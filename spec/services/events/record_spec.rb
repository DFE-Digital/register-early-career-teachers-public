RSpec.describe Events::Record do
  include ActiveJob::TestHelper

  let(:user) { FactoryBot.create(:user, name: 'Christopher Biggins', email: 'christopher.biggins@education.gov.uk') }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Rhys', trs_last_name: 'Ifans') }
  let(:induction_period) { FactoryBot.create(:induction_period) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Burns Slant Drilling Co.") }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:author_params) { { author_id: author.id, author_name: author.name, author_email: author.email, author_type: :dfe_staff_user } }
  let(:another_dfe_user) { FactoryBot.create(:user, name: 'Ian Richardson', email: 'er@education.gov.uk') }

  let(:heading) { 'Something happened' }
  let(:event_type) { :induction_period_opened }
  let(:body) { 'A very important event' }
  let(:happened_at) { 2.minutes.ago }

  before { allow(RecordEventJob).to receive(:perform_later).and_call_original }

  around do |example|
    perform_enqueued_jobs { example.run }
  end

  describe '#initialize' do
    context 'when the user is not supported' do
      let(:non_session_user) { FactoryBot.build(:user) }

      it 'fails when author object does not respond with necessary params' do
        expect {
          Events::Record.new(author: non_session_user, event_type:, heading:, body:, happened_at:).record_event!
        }.to raise_error(Events::InvalidAuthor)
      end
    end

    it 'assigns and saves attributes correctly' do
      ect_at_school_period = FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.weeks.ago)
      mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: 3.weeks.ago)

      attributes = {
        author:,
        event_type:,
        heading:,
        body:,
        happened_at:,
        induction_period:,
        teacher:,
        school: FactoryBot.create(:school),
        appropriate_body: FactoryBot.create(:appropriate_body),
        induction_extension: FactoryBot.create(:induction_extension),
        ect_at_school_period:,
        mentor_at_school_period:,
        school_partnership: FactoryBot.create(:school_partnership),
        lead_provider: FactoryBot.create(:lead_provider),
        delivery_partner: FactoryBot.create(:delivery_partner),
        user: FactoryBot.create(:user),
        training_period: FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: 1.week.ago),
        mentorship_period: FactoryBot.create(
          :mentorship_period,
          mentor: mentor_at_school_period,
          mentee: ect_at_school_period,
          started_on: 1.week.ago,
          finished_on: nil
        ),
      }

      event_record = Events::Record.new(author:, **attributes)

      expect(event_record.author).to eql(author)

      attributes.each_key do |key|
        expect(event_record.send(key)).to eql(attributes.fetch(key))
      end

      event_attributes = { **author.event_author_params, **attributes.except(:author) }

      allow(RecordEventJob).to receive(:perform_later).with(**event_attributes).and_return(true)

      event_record.record_event!

      expect(RecordEventJob).to have_received(:perform_later).with(**event_attributes)
    end
  end

  describe '#record_event!' do
    {
      induction_period: FactoryBot.build(:induction_period),
      teacher: FactoryBot.build(:teacher),
      school: FactoryBot.build(:school),
      appropriate_body: FactoryBot.build(:appropriate_body),
      induction_extension: FactoryBot.build(:induction_extension),
      ect_at_school_period: FactoryBot.build(:ect_at_school_period),
      mentor_at_school_period: FactoryBot.build(:mentor_at_school_period),
      school_partnership: FactoryBot.build(:school_partnership),
      lead_provider: FactoryBot.build(:lead_provider),
      delivery_partner: FactoryBot.build(:delivery_partner),
      user: FactoryBot.build(:user),
      training_period: FactoryBot.build(:training_period),
      mentorship_period: FactoryBot.build(:mentorship_period),
    }.each do |attribute, object|
      describe "when #{attribute} is missing" do
        subject { Events::Record.new(author:, event_type:, heading:, happened_at:, **attributes_with_unsaved_school) }

        let(:attributes_with_unsaved_school) { { attribute => object } }

        it 'fails with a NotPersistedRecordError' do
          expect { subject.record_event! }.to raise_error(Events::NotPersistedRecord, attribute.to_s)
        end
      end
    end
  end

  describe '.record_induction_period_opened_event!' do
    it 'queues a RecordEventJob with the correct values' do
      raw_modifications = induction_period.changes

      freeze_time do
        Events::Record.record_induction_period_opened_event!(author:, teacher:, appropriate_body:, induction_period:, modifications: raw_modifications)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_period:,
          teacher:,
          appropriate_body:,
          heading: 'Rhys Ifans was claimed by Burns Slant Drilling Co.',
          event_type: :induction_period_opened,
          happened_at: induction_period.started_on,
          modifications: anything,
          metadata: raw_modifications,
          **author_params
        )
      end
    end

    it 'fails when induction period is missing' do
      expect {
        Events::Record.record_induction_period_opened_event!(author:, teacher:, appropriate_body:, induction_period: nil, modifications: {})
      }.to raise_error(Events::NoInductionPeriod)
    end
  end

  describe '.record_induction_period_closed_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_induction_period_closed_event!(author:, teacher:, appropriate_body:, induction_period:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_period:,
          teacher:,
          appropriate_body:,
          heading: 'Rhys Ifans was released by Burns Slant Drilling Co.',
          event_type: :induction_period_closed,
          happened_at: induction_period.finished_on,
          **author_params
        )
      end
    end

    it 'fails when induction period is missing' do
      expect {
        Events::Record.record_induction_period_closed_event!(author:, teacher:, appropriate_body:, induction_period: nil)
      }.to raise_error(Events::NoInductionPeriod)
    end
  end

  describe '.record_teacher_passes_induction_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_passes_induction_event!(author:, teacher:, appropriate_body:, induction_period:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_period:,
          teacher:,
          appropriate_body:,
          heading: 'Rhys Ifans passed induction',
          event_type: :teacher_passes_induction,
          happened_at: induction_period.finished_on,
          **author_params
        )
      end
    end

    it 'fails when induction period is missing' do
      expect {
        Events::Record.record_teacher_fails_induction_event!(author:, teacher:, appropriate_body:, induction_period: nil)
      }.to raise_error(Events::NoInductionPeriod)
    end
  end

  describe '.record_teacher_fails_induction_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_fails_induction_event!(author:, teacher:, appropriate_body:, induction_period:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_period:,
          teacher:,
          appropriate_body:,
          heading: 'Rhys Ifans failed induction',
          event_type: :teacher_fails_induction,
          happened_at: induction_period.finished_on,
          **author_params
        )
      end
    end

    it 'fails when induction period is missing' do
      expect {
        Events::Record.record_teacher_fails_induction_event!(author:, teacher:, appropriate_body:, induction_period: nil)
      }.to raise_error(Events::NoInductionPeriod)
    end
  end

  describe '.record_admin_passes_teacher_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_admin_passes_teacher_event!(author:, teacher:, appropriate_body:, induction_period:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_period:,
          teacher:,
          appropriate_body:,
          heading: 'Rhys Ifans passed induction (admin)',
          event_type: :teacher_passes_induction,
          happened_at: induction_period.finished_on,
          **author_params
        )
      end
    end

    it 'fails when induction period is missing' do
      expect {
        Events::Record.record_admin_passes_teacher_event!(author:, teacher:, appropriate_body:, induction_period: nil)
      }.to raise_error(Events::NoInductionPeriod)
    end
  end

  describe '.record_admin_fails_teacher_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_admin_fails_teacher_event!(author:, teacher:, appropriate_body:, induction_period:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_period:,
          teacher:,
          appropriate_body:,
          heading: 'Rhys Ifans failed induction (admin)',
          event_type: :teacher_fails_induction,
          happened_at: induction_period.finished_on,
          **author_params
        )
      end
    end

    it 'fails when induction period is missing' do
      expect {
        Events::Record.record_admin_fails_teacher_event!(author:, teacher:, appropriate_body:, induction_period: nil)
      }.to raise_error(Events::NoInductionPeriod)
    end
  end

  describe '.record_induction_period_deleted_event!' do
    let(:raw_modifications) { { 'id' => 1, 'teacher_id' => teacher.id, 'appropriate_body_id' => appropriate_body.id } }

    context 'when induction status was reset on TRS' do
      it 'queues a RecordEventJob with the correct values including body' do
        freeze_time do
          Events::Record.record_induction_period_deleted_event!(
            author:,
            teacher:,
            appropriate_body:,
            modifications: raw_modifications,
            body: "Induction status was reset to 'Required to Complete' in TRS."
          )

          expect(RecordEventJob).to have_received(:perform_later).with(
            teacher:,
            appropriate_body:,
            heading: 'Induction period deleted by admin',
            event_type: :induction_period_deleted,
            happened_at: Time.zone.now,
            body: "Induction status was reset to 'Required to Complete' in TRS.",
            modifications: anything,
            metadata: raw_modifications,
            **author_params
          )
        end
      end
    end

    context 'when induction status was not reset on TRS' do
      it 'queues a RecordEventJob with the correct values without body' do
        freeze_time do
          Events::Record.record_induction_period_deleted_event!(
            author:,
            teacher:,
            appropriate_body:,
            modifications: raw_modifications
          )

          expect(RecordEventJob).to have_received(:perform_later).with(
            teacher:,
            appropriate_body:,
            heading: 'Induction period deleted by admin',
            event_type: :induction_period_deleted,
            happened_at: Time.zone.now,
            modifications: anything,
            metadata: raw_modifications,
            **author_params
          )
        end
      end
    end
  end

  describe '.record_induction_extension_created_event!' do
    let(:induction_extension) { FactoryBot.build(:induction_extension) }

    it 'queues a RecordEventJob with the correct values' do
      raw_modifications = induction_extension.changes
      induction_extension.save!

      freeze_time do
        Events::Record.record_induction_extension_created_event!(author:, teacher:, appropriate_body:, induction_extension:, modifications: raw_modifications)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_extension:,
          teacher:,
          appropriate_body:,
          heading: "Rhys Ifans's induction extended by 1.2 terms",
          event_type: :induction_extension_created,
          happened_at: Time.zone.now,
          modifications: ["Number of terms set to '1.2'"],
          metadata: raw_modifications,
          **author_params
        )
      end
    end
  end

  describe '.record_induction_extension_updated_event!' do
    let(:induction_extension) { FactoryBot.create(:induction_extension) }

    it 'queues a RecordEventJob with the correct values' do
      induction_extension.assign_attributes(number_of_terms: 3.2)
      raw_modifications = induction_extension.changes

      freeze_time do
        Events::Record.record_induction_extension_updated_event!(author:, teacher:, appropriate_body:, induction_extension:, modifications: raw_modifications)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_extension:,
          teacher:,
          appropriate_body:,
          heading: "Rhys Ifans's induction extended by 3.2 terms",
          event_type: :induction_extension_updated,
          happened_at: Time.zone.now,
          modifications: ["Number of terms changed from '1.2' to '3.2'"],
          metadata: raw_modifications,
          **author_params
        )
      end
    end
  end

  describe '.record_induction_period_updated_event!' do
    let(:three_weeks_ago) { 3.weeks.ago.to_date }
    let(:two_weeks_ago) { 2.weeks.ago.to_date }
    let(:induction_period) { FactoryBot.create(:induction_period, :ongoing, started_on: three_weeks_ago) }

    it 'queues a RecordEventJob with the correct values' do
      induction_period.assign_attributes(started_on: two_weeks_ago)
      raw_modifications = induction_period.changes

      freeze_time do
        Events::Record.record_induction_period_updated_event!(author:, teacher:, appropriate_body:, induction_period:, modifications: raw_modifications)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_period:,
          teacher:,
          appropriate_body:,
          heading: 'Induction period updated by admin',
          event_type: :induction_period_updated,
          happened_at: Time.zone.now,
          modifications: ["Started on changed from '#{3.weeks.ago.to_date.to_formatted_s(:govuk_short)}' to '#{2.weeks.ago.to_date.to_formatted_s(:govuk_short)}'"],
          metadata: raw_modifications,
          **author_params
        )
      end
    end
  end

  describe '.teacher_name_changed_in_trs_event!' do
    let(:old_name) { 'Wilfred Bramble' }
    let(:new_name) { 'Willy Brambs' }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.teacher_name_changed_in_trs_event!(author:, teacher:, appropriate_body:, old_name:, new_name:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          appropriate_body:,
          heading: "Name changed from 'Wilfred Bramble' to 'Willy Brambs'",
          event_type: :teacher_name_updated_by_trs,
          happened_at: Time.zone.now,
          **author_params
        )
      end
    end
  end

  describe '.teacher_induction_status_changed_in_trs_event!' do
    let(:old_induction_status) { 'InProgress' }
    let(:new_induction_status) { 'Exempt' }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.teacher_induction_status_changed_in_trs_event!(author:, teacher:, appropriate_body:, old_induction_status:, new_induction_status:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          appropriate_body:,
          heading: "Induction status changed from 'InProgress' to 'Exempt'",
          event_type: :teacher_trs_induction_status_updated,
          happened_at: Time.zone.now,
          **author_params
        )
      end
    end
  end

  describe '.record_teacher_trs_induction_start_date_updated_event!' do
    let(:old_date) { Date.new(2020, 1, 1) }
    let(:new_date) { Date.new(2021, 1, 1) }
    let(:teacher_name) { Teachers::Name.new(teacher).full_name }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_trs_induction_start_date_updated_event!(author:, teacher:, appropriate_body:, induction_period:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          appropriate_body:,
          heading: "#{teacher_name}'s induction start date was updated",
          event_type: :teacher_trs_induction_start_date_updated,
          happened_at: Time.zone.now,
          induction_period:,
          **author_params
        )
      end
    end
  end

  describe '.teacher_imported_from_trs_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.teacher_imported_from_trs_event!(author:, teacher:, appropriate_body:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          appropriate_body:,
          heading: "Imported from TRS",
          event_type: :teacher_imported_from_trs,
          happened_at: Time.zone.now,
          **author_params
        )
      end
    end
  end

  describe '.teacher_trs_attributes_updated_event!' do
    it 'queues a RecordEventJob with the correct values' do
      teacher.assign_attributes(trs_first_name: 'Otto', trs_last_name: 'Hightower')
      modifications = teacher.changes
      freeze_time do
        Events::Record.teacher_trs_attributes_updated_event!(author:, teacher:, modifications:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          heading: "TRS attributes updated",
          event_type: :teacher_trs_attributes_updated,
          happened_at: Time.zone.now,
          metadata: {
            "trs_first_name" => %w[Rhys Otto],
            "trs_last_name" => %w[Ifans Hightower],
          },
          modifications: [
            "TRS first name changed from 'Rhys' to 'Otto'",
            "TRS last name changed from 'Ifans' to 'Hightower'"
          ],
          **author_params
        )
      end
    end
  end

  describe '.record_teacher_trs_deactivated_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_trs_deactivated_event!(author:, teacher:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          heading: "Rhys Ifans was deactivated in TRS",
          event_type: :teacher_trs_deactivated,
          happened_at: Time.zone.now,
          body: "TRS API returned 410 so the record was marked as deactivated",
          **author_params
        )
      end
    end
  end

  describe 'record_teacher_induction_status_reset_event!' do
    let(:event_type) { :teacher_induction_status_reset }
    let(:happened_at) { Time.zone.now }

    context 'when induction status was reset on TRS' do
      it 'records an event with the correct values including body' do
        freeze_time do
          event = Events::Record.new(
            author:,
            teacher:,
            appropriate_body:,
            event_type:,
            heading: "#{Teachers::Name.new(teacher).full_name} was unclaimed by support",
            happened_at:
          )

          allow(event).to receive(:record_event!).and_return(true)
          expect(event).to receive(:record_event!)

          event.record_event!

          expect(event.event_type).to eq(event_type)
          expect(event.teacher).to eq(teacher)
          expect(event.appropriate_body).to eq(appropriate_body)
        end
      end
    end

    context 'when induction status was not reset on TRS' do
      it 'records an event with the correct values without body' do
        freeze_time do
          event = Events::Record.new(
            author:,
            teacher:,
            appropriate_body:,
            event_type:,
            heading: "#{Teachers::Name.new(teacher).full_name} was unclaimed by support",
            happened_at:
          )

          allow(event).to receive(:record_event!).and_return(true)
          expect(event).to receive(:record_event!)

          event.record_event!

          expect(event.event_type).to eq(event_type)
          expect(event.teacher).to eq(teacher)
          expect(event.appropriate_body).to eq(appropriate_body)
          expect(event.body).to be_nil
        end
      end
    end
  end

  describe '.record_teacher_induction_status_reset_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_induction_status_reset_event!(author:, teacher:, appropriate_body:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          appropriate_body:,
          heading: 'Rhys Ifans was unclaimed',
          event_type: :teacher_induction_status_reset,
          happened_at: Time.zone.now,
          **author_params
        )
      end
    end
  end

  describe '.record_induction_period_reopened_event!' do
    let(:induction_period) { FactoryBot.create(:induction_period, :pass, teacher:, appropriate_body:) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        induction_period.outcome = nil
        induction_period.finished_on = nil
        induction_period.number_of_terms = nil
        raw_modifications = induction_period.changes

        Events::Record.record_induction_period_reopened_event!(
          author:,
          induction_period:,
          modifications: raw_modifications,
          teacher:,
          appropriate_body:,
          body: "A test note",
          zendesk_ticket_id: "1234"
        )

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          induction_period:,
          appropriate_body:,
          heading: 'Induction period reopened',
          event_type: :induction_period_reopened,
          happened_at: Time.zone.now,
          modifications: anything,
          metadata: raw_modifications,
          body: "A test note",
          zendesk_ticket_id: "1234",
          **author_params
        )
      end
    end
  end

  describe '.record_teacher_registered_as_mentor_event!' do
    let(:school) { FactoryBot.create(:school) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: Date.new(2024, 9, 10), finished_on: Date.new(2025, 7, 20)) }
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_mentor,
        :with_school_partnership,
        mentor_at_school_period:,
        started_on: mentor_at_school_period.started_on,
        finished_on: mentor_at_school_period.finished_on
      )
    end

    let(:lead_provider) { FactoryBot.create(:lead_provider) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_registered_as_mentor_event!(author:, teacher:, mentor_at_school_period:, school:, training_period:, lead_provider:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          school:,
          training_period:,
          mentor_at_school_period:,
          heading: "Rhys Ifans was registered as a mentor at #{school.name}",
          event_type: :teacher_registered_as_mentor,
          happened_at: Time.zone.now,
          lead_provider:,
          **author_params
        )
      end
    end
  end

  describe '.record_teacher_registered_as_ect_event!' do
    let(:school) { FactoryBot.create(:school) }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: Date.new(2024, 9, 10), finished_on: Date.new(2025, 7, 20)) }
    let(:training_period) { FactoryBot.create(:training_period, ect_at_school_period:, started_on: Date.new(2024, 9, 10), finished_on: Date.new(2025, 7, 20)) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_registered_as_ect_event!(author:, teacher:, ect_at_school_period:, school:, training_period:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          school:,
          ect_at_school_period:,
          training_period:,
          heading: "Rhys Ifans was registered as an ECT at #{school.name}",
          event_type: :teacher_registered_as_ect,
          schedule: training_period.schedule,
          happened_at: Time.zone.now,
          **author_params
        )
      end
    end
  end

  describe '.record_teacher_left_school_as_ect!' do
    let(:finished_on) { Date.new(2025, 7, 20) }
    let(:school) { FactoryBot.create(:school) }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: Date.new(2024, 9, 10), finished_on:) }
    let(:training_period) { FactoryBot.create(:training_period, ect_at_school_period:, started_on: Date.new(2024, 9, 10), finished_on:) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_left_school_as_ect!(author:, teacher:, ect_at_school_period:, school:, training_period:, happened_at: finished_on)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          school:,
          ect_at_school_period:,
          training_period:,
          heading: "Rhys Ifans left #{school.name}",
          event_type: :teacher_left_school_as_ect,
          happened_at: finished_on,
          **author_params
        )
      end
    end
  end

  describe '.record_teacher_starts_training_period_event' do
    let(:started_on) { Date.new(2023, 7, 20) }
    let(:started_on_param) { { started_on: } }
    let(:school) { FactoryBot.create(:school) }

    context 'when ECT training' do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:, **started_on_param) }
      let(:training_period) { FactoryBot.create(:training_period, ect_at_school_period:, **started_on_param) }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_teacher_starts_training_period_event!(author:, teacher:, mentor_at_school_period: nil, ect_at_school_period:, school:, training_period:, happened_at: started_on)

          expect(RecordEventJob).to have_received(:perform_later).with(
            teacher:,
            school:,
            ect_at_school_period:,
            training_period:,
            heading: "Rhys Ifans started a new ECT training period",
            event_type: :teacher_starts_training_period,
            happened_at: started_on,
            **author_params
          )
        end
      end
    end

    context 'when mentor training' do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, **started_on_param) }
      let(:training_period) { FactoryBot.create(:training_period, mentor_at_school_period:, ect_at_school_period: nil, **started_on_param) }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_teacher_starts_training_period_event!(author:, teacher:, mentor_at_school_period:, ect_at_school_period: nil, school:, training_period:, happened_at: started_on)

          expect(RecordEventJob).to have_received(:perform_later).with(
            teacher:,
            school:,
            mentor_at_school_period:,
            training_period:,
            heading: "Rhys Ifans started a new mentor training period",
            event_type: :teacher_starts_training_period,
            happened_at: started_on,
            **author_params
          )
        end
      end
    end

    describe 'errors' do
      let(:training_period) { FactoryBot.build(:training_period) }

      it 'fails when both mentor_at_school_period and ect_at_school_period are passed in' do
        expect {
          Events::Record.record_teacher_starts_training_period_event!(author:, teacher:, mentor_at_school_period: 'a', ect_at_school_period: 'b', school:, training_period:, happened_at: started_on)
        }.to raise_error(ArgumentError, 'either ect_at_school_period or mentor_at_school_period permitted, not both')
      end

      it 'fails when neither mentor_at_school_period or ect_at_school_period are passed in' do
        expect {
          Events::Record.record_teacher_starts_training_period_event!(author:, teacher:, mentor_at_school_period: nil, ect_at_school_period: nil, school:, training_period:, happened_at: started_on)
        }.to raise_error(ArgumentError, 'either ect_at_school_period or mentor_at_school_period is required')
      end
    end
  end

  describe '.record_teacher_finishes_training_period_event' do
    let(:started_on) { Date.new(2023, 7, 20) }
    let(:finished_on) { Date.new(2025, 7, 20) }
    let(:date_params) { { started_on:, finished_on: } }
    let(:school) { FactoryBot.create(:school) }

    context 'when ECT training' do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:, **date_params) }
      let(:training_period) { FactoryBot.create(:training_period, ect_at_school_period:, **date_params) }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_teacher_finishes_training_period_event!(author:, teacher:, mentor_at_school_period: nil, ect_at_school_period:, school:, training_period:, happened_at: finished_on)

          expect(RecordEventJob).to have_received(:perform_later).with(
            teacher:,
            school:,
            ect_at_school_period:,
            training_period:,
            heading: "Rhys Ifans finished their ECT training period",
            event_type: :teacher_finishes_training_period,
            happened_at: finished_on,
            **author_params
          )
        end
      end
    end

    context 'when mentor training' do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, **date_params) }
      let(:training_period) { FactoryBot.create(:training_period, mentor_at_school_period:, ect_at_school_period: nil, **date_params) }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_teacher_finishes_training_period_event!(author:, teacher:, mentor_at_school_period:, ect_at_school_period: nil, school:, training_period:, happened_at: finished_on)

          expect(RecordEventJob).to have_received(:perform_later).with(
            teacher:,
            school:,
            mentor_at_school_period:,
            training_period:,
            heading: "Rhys Ifans finished their mentor training period",
            event_type: :teacher_finishes_training_period,
            happened_at: finished_on,
            **author_params
          )
        end
      end
    end

    describe 'errors' do
      let(:training_period) { FactoryBot.build(:training_period) }

      it 'fails when both mentor_at_school_period and ect_at_school_period are passed in' do
        expect {
          Events::Record.record_teacher_finishes_training_period_event!(author:, teacher:, mentor_at_school_period: 'a', ect_at_school_period: 'b', school:, training_period:, happened_at: started_on)
        }.to raise_error(ArgumentError, 'either ect_at_school_period or mentor_at_school_period permitted, not both')
      end

      it 'fails when neither the mentor_at_school_period or ect_at_school_period are passed in' do
        expect {
          Events::Record.record_teacher_finishes_training_period_event!(author:, teacher:, mentor_at_school_period: nil, ect_at_school_period: nil, school:, training_period:, happened_at: started_on)
        }.to raise_error(ArgumentError, 'either ect_at_school_period or mentor_at_school_period is required')
      end
    end
  end

  describe '.record_teacher_starts_mentoring_event!' do
    let(:started_on_param) { { started_on: 2.years.ago.to_date } }
    let(:school) { FactoryBot.create(:school) }
    let(:mentee) { FactoryBot.create(:teacher, trs_first_name: 'Steffan', trs_last_name: 'Rhodri') }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: mentee, school:, **started_on_param) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:, **started_on_param) }
    let(:mentorship_period) { FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on: 2.days.ago.to_date) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_starts_mentoring_event!(author:, mentee:, mentor: teacher, mentorship_period:, mentor_at_school_period:, school:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          school: mentor_at_school_period.school,
          mentor_at_school_period:,
          mentorship_period:,
          heading: "Rhys Ifans started mentoring Steffan Rhodri",
          event_type: :teacher_starts_mentoring,
          happened_at: Time.zone.now,
          metadata: { mentor_id: teacher.id, mentee_id: mentee.id },
          **author_params
        )
      end
    end
  end

  describe '.record_teacher_starts_being_mentored_event!' do
    let(:started_on_param) { { started_on: 2.years.ago.to_date } }
    let(:school) { FactoryBot.create(:school) }
    let(:mentor) { FactoryBot.create(:teacher, trs_first_name: 'Steffan', trs_last_name: 'Rhodri') }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:, **started_on_param) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: mentor, school:, **started_on_param) }
    let(:mentorship_period) { FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on: 2.days.ago.to_date) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_starts_being_mentored_event!(author:, mentee: teacher, mentor:, mentorship_period:, ect_at_school_period:, school:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          school: ect_at_school_period.school,
          ect_at_school_period:,
          mentorship_period:,
          heading: "Rhys Ifans is being mentored by Steffan Rhodri",
          event_type: :teacher_starts_being_mentored,
          happened_at: Time.zone.now,
          metadata: { mentor_id: mentor.id, mentee_id: teacher.id },
          **author_params
        )
      end
    end
  end

  describe '.record_teacher_finishes_mentoring_event!' do
    let(:finished_on) { 1.month.ago.to_date }
    let(:started_on_param) { { started_on: 2.years.ago.to_date } }
    let(:finished_on_param) { { finished_on: } }
    let(:school) { FactoryBot.create(:school) }
    let(:mentee) { FactoryBot.create(:teacher, trs_first_name: 'Steffan', trs_last_name: 'Rhodri') }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: mentee, school:, **started_on_param) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:, **started_on_param, **finished_on_param) }
    let(:mentorship_period) { FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on: 2.months.ago.to_date) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_finishes_mentoring_event!(author:, mentee:, mentor: teacher, mentorship_period:, mentor_at_school_period:, school:, happened_at: finished_on)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          school: mentor_at_school_period.school,
          mentor_at_school_period:,
          mentorship_period:,
          heading: "Rhys Ifans finished mentoring Steffan Rhodri",
          event_type: :teacher_finishes_mentoring,
          happened_at: finished_on,
          metadata: { mentor_id: teacher.id, mentee_id: mentee.id },
          **author_params
        )
      end
    end
  end

  describe '.record_teacher_finishes_being_mentored_event!' do
    let(:finished_on) { 1.month.ago.to_date }
    let(:started_on_param) { { started_on: 2.years.ago.to_date } }
    let(:finished_on_param) { { finished_on: } }
    let(:school) { FactoryBot.create(:school) }
    let(:mentor) { FactoryBot.create(:teacher, trs_first_name: 'Steffan', trs_last_name: 'Rhodri') }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:, **started_on_param) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: mentor, school:, **started_on_param) }
    let(:mentorship_period) { FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on: 2.months.ago.to_date) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_finishes_being_mentored_event!(author:, mentee: teacher, mentor:, mentorship_period:, ect_at_school_period:, school:, happened_at: finished_on)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          school: ect_at_school_period.school,
          ect_at_school_period:,
          mentorship_period:,
          heading: "Rhys Ifans is no longer being mentored by Steffan Rhodri",
          event_type: :teacher_finishes_being_mentored,
          happened_at: finished_on,
          metadata: { mentor_id: mentor.id, mentee_id: teacher.id },
          **author_params
        )
      end
    end
  end

  describe ".record_teacher_email_updated_event" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, teacher:, email: "old@example.com")
    end

    it "enqueues a RecordEventJob with the correct values" do
      freeze_time

      Events::Record.record_teacher_email_updated_event!(
        old_email: ect_at_school_period.email,
        new_email: "new@example.com",
        author:,
        ect_at_school_period:,
        school: ect_at_school_period.school,
        teacher:,
        happened_at: 5.minutes.ago
      )

      expect(RecordEventJob).to have_received(:perform_later).with(
        teacher:,
        school: ect_at_school_period.school,
        ect_at_school_period:,
        heading: "Email address changed from 'old@example.com' to 'new@example.com'",
        event_type: :teacher_email_address_updated,
        happened_at: 5.minutes.ago,
        **author_params
      )
    end
  end

  describe ".record_teacher_working_pattern_updated_event!" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, teacher:, working_pattern: :full_time)
    end

    it "enqueues a RecordEventJob with the correct values" do
      freeze_time

      Events::Record.record_teacher_working_pattern_updated_event!(
        old_working_pattern: ect_at_school_period.working_pattern,
        new_working_pattern: "part_time",
        author:,
        ect_at_school_period:,
        school: ect_at_school_period.school,
        teacher:,
        happened_at: 15.seconds.ago
      )

      expect(RecordEventJob).to have_received(:perform_later).with(
        teacher:,
        school: ect_at_school_period.school,
        ect_at_school_period:,
        heading: "Working pattern changed from 'full time' to 'part time'",
        event_type: :teacher_working_pattern_updated,
        happened_at: 15.seconds.ago,
        **author_params
      )
    end
  end

  describe ".record_teacher_training_programme_updated_event!" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }

    it "enqueues a RecordEventJob with the correct values" do
      freeze_time

      Events::Record.record_teacher_training_programme_updated_event!(
        old_training_programme: "school_led",
        new_training_programme: "provider_led",
        author:,
        ect_at_school_period:,
        school: ect_at_school_period.school,
        teacher:,
        happened_at: 25.minutes.ago
      )

      expect(RecordEventJob).to have_received(:perform_later).with(
        teacher:,
        school: ect_at_school_period.school,
        ect_at_school_period:,
        heading: "Training programme changed from 'school led' to 'provider led'",
        event_type: :teacher_training_programme_updated,
        happened_at: 25.minutes.ago,
        **author_params
      )
    end
  end

  describe ".record_teacher_training_lead_provider_updated_event!" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }

    it "enqueues a RecordEventJob with the correct values" do
      freeze_time

      Events::Record.record_teacher_training_lead_provider_updated_event!(
        old_lead_provider_name: "Old Lead Provider",
        new_lead_provider_name: "New Lead Provider",
        author:,
        ect_at_school_period:,
        mentor_at_school_period:,
        school: ect_at_school_period.school,
        teacher:,
        happened_at: 5.minutes.ago
      )

      expect(RecordEventJob).to have_received(:perform_later).with(
        teacher:,
        school: ect_at_school_period.school,
        ect_at_school_period:,
        mentor_at_school_period:,
        heading: "Lead provider changed from 'Old Lead Provider' to 'New Lead Provider'",
        event_type: :teacher_training_lead_provider_updated,
        happened_at: 5.minutes.ago,
        **author_params
      )
    end
  end

  describe '.record_teacher_left_school_as_mentor!' do
    let(:finished_on) { 1.month.ago.to_date }
    let(:school) { FactoryBot.create(:school) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:, started_on: 2.years.ago.to_date) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_left_school_as_mentor!(
          author:,
          mentor_at_school_period:,
          teacher:,
          school:,
          happened_at: finished_on
        )

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          school:,
          mentor_at_school_period:,
          heading: "Rhys Ifans left #{school.name}",
          event_type: :teacher_left_school_as_mentor,
          happened_at: finished_on,
          **author_params
        )
      end
    end
  end

  describe '.record_teacher_training_period_withdrawn_event' do
    let(:teacher) { training_period.trainee.teacher }
    let(:lead_provider) { training_period.lead_provider }
    let(:reason) { "left_teaching_profession" }
    let(:teacher_name) { Teachers::Name.new(teacher).full_name }
    let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
    let(:author_params) { { author_name: lead_provider.name, author_type: 'lead_provider_api' } }
    let(:modifications) do
      {
        "withdrawal_reason" => [nil, reason],
        "withdraw_at" => [nil, Time.zone.now],
        "finished_on" => [nil, Time.zone.today],
        "updated_at" => [training_period.updated_at, Time.zone.now]
      }
    end

    context 'when ECT training' do
      let(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing) }
      let(:course_identifier) { "ecf-induction" }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_teacher_training_period_withdrawn_event!(author:, training_period:, teacher:, lead_provider:, modifications:)

          expect(RecordEventJob).to have_received(:perform_later).with(
            training_period:,
            teacher:,
            lead_provider:,
            metadata: modifications,
            modifications: anything,
            heading: "#{teacher_name}’s ECT training period was withdrawn by #{lead_provider.name}",
            event_type: :teacher_withdraws_training_period,
            happened_at: Time.zone.now,
            **author_params
          )
        end
      end
    end

    context 'when Mentor training' do
      let(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing) }
      let(:course_identifier) { "ecf-mentor" }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_teacher_training_period_withdrawn_event!(author:, training_period:, teacher:, lead_provider:, modifications:)

          expect(RecordEventJob).to have_received(:perform_later).with(
            training_period:,
            teacher:,
            lead_provider:,
            metadata: modifications,
            modifications: anything,
            heading: "#{teacher_name}’s mentor training period was withdrawn by #{lead_provider.name}",
            event_type: :teacher_withdraws_training_period,
            happened_at: Time.zone.now,
            **author_params
          )
        end
      end
    end
  end

  describe '.record_teacher_training_period_deferred_event' do
    let(:lead_provider) { training_period.lead_provider }
    let(:reason) { "career_break" }
    let(:teacher_name) { Teachers::Name.new(teacher).full_name }
    let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
    let(:author_params) { { author_name: lead_provider.name, author_type: 'lead_provider_api' } }
    let(:modifications) do
      {
        "deferral_reason" => [nil, reason],
        "deferred_at" => [nil, Time.zone.now],
        "finished_on" => [nil, Time.zone.today],
        "updated_at" => [training_period.updated_at, Time.zone.now]
      }
    end

    context 'when ECT training' do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: Date.new(2024, 9, 10), finished_on: Date.new(2025, 7, 20)) }
      let(:training_period) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: Date.new(2024, 9, 10), finished_on: Date.new(2025, 7, 20)) }
      let(:course_identifier) { "ecf-induction" }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_teacher_training_period_deferred_event!(author:, training_period:, teacher:, lead_provider:, modifications:)

          expect(RecordEventJob).to have_received(:perform_later).with(
            training_period:,
            teacher:,
            lead_provider:,
            metadata: modifications,
            modifications: anything,
            heading: "#{teacher_name}’s ECT training period was deferred by #{lead_provider.name}",
            event_type: :teacher_defers_training_period,
            happened_at: Time.zone.now,
            **author_params
          )
        end
      end
    end

    context 'when Mentor training' do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, started_on: Date.new(2024, 9, 10), finished_on: Date.new(2025, 7, 20)) }
      let(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:, started_on: Date.new(2024, 9, 10), finished_on: Date.new(2025, 7, 20)) }
      let(:course_identifier) { "ecf-mentor" }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_teacher_training_period_deferred_event!(author:, training_period:, teacher:, lead_provider:, modifications:)

          expect(RecordEventJob).to have_received(:perform_later).with(
            training_period:,
            teacher:,
            lead_provider:,
            metadata: modifications,
            modifications: anything,
            heading: "#{teacher_name}’s mentor training period was deferred by #{lead_provider.name}",
            event_type: :teacher_defers_training_period,
            happened_at: Time.zone.now,
            **author_params
          )
        end
      end
    end
  end

  describe '.record_teacher_training_period_resumed_event' do
    let(:lead_provider) { training_period.lead_provider }
    let(:teacher_name) { Teachers::Name.new(teacher).full_name }
    let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
    let(:author_params) { { author_name: lead_provider.name, author_type: 'lead_provider_api' } }
    let(:metadata) {  { new_training_period_id: training_period.id } }

    context 'when ECT training' do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: Date.new(2024, 9, 10), finished_on: Date.new(2025, 7, 20)) }
      let(:training_period) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: Date.new(2024, 9, 10), finished_on: Date.new(2025, 7, 20)) }
      let(:course_identifier) { "ecf-induction" }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_teacher_training_period_resumed_event!(author:, training_period:, teacher:, lead_provider:, metadata:)

          expect(RecordEventJob).to have_received(:perform_later).with(
            training_period:,
            teacher:,
            lead_provider:,
            metadata: anything,
            heading: "#{teacher_name}’s ECT training period was resumed by #{lead_provider.name}",
            event_type: :teacher_resumes_training_period,
            happened_at: Time.zone.now,
            **author_params
          )
        end
      end
    end

    context 'when Mentor training' do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, started_on: Date.new(2024, 9, 10), finished_on: Date.new(2025, 7, 20)) }
      let(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:, started_on: Date.new(2024, 9, 10), finished_on: Date.new(2025, 7, 20)) }
      let(:course_identifier) { "ecf-mentor" }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_teacher_training_period_resumed_event!(author:, training_period:, teacher:, lead_provider:, metadata:)

          expect(RecordEventJob).to have_received(:perform_later).with(
            training_period:,
            teacher:,
            lead_provider:,
            metadata: anything,
            heading: "#{teacher_name}’s mentor training period was resumed by #{lead_provider.name}",
            event_type: :teacher_resumes_training_period,
            happened_at: Time.zone.now,
            **author_params
          )
        end
      end
    end
  end

  describe '.record_bulk_upload_started_event!' do
    let(:batch) { FactoryBot.create(:pending_induction_submission_batch, :action, appropriate_body:) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_bulk_upload_started_event!(author:, batch:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          heading: "Burns Slant Drilling Co. started a bulk action",
          appropriate_body:,
          pending_induction_submission_batch: batch,
          event_type: :bulk_upload_started,
          happened_at: Time.zone.now,
          **author_params
        )
      end
    end
  end

  describe '.record_bulk_upload_completed_event!' do
    let(:batch) { FactoryBot.create(:pending_induction_submission_batch, :claim, appropriate_body:) }

    include_context 'test trs api client'

    before do
      AppropriateBodies::ProcessBatch::ClaimJob.perform_now(batch, author.email, author.name)
    end

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_bulk_upload_completed_event!(author:, batch:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          heading: "Burns Slant Drilling Co. completed a bulk claim",
          appropriate_body:,
          pending_induction_submission_batch: batch,
          event_type: :bulk_upload_completed,
          happened_at: Time.zone.now,
          **author_params
        )
      end
    end
  end

  describe '.record_lead_provider_api_token_created_event!' do
    let(:api_token) { FactoryBot.create(:api_token) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_lead_provider_api_token_created_event!(author:, api_token:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          heading: "An API token was created for lead provider: #{api_token.lead_provider.name}",
          lead_provider: api_token.lead_provider,
          event_type: :lead_provider_api_token_created,
          happened_at: Time.zone.now,
          metadata: { description: api_token.description },
          **author_params
        )
      end
    end
  end

  describe '.record_lead_provider_api_token_revoked_event!' do
    let(:api_token) { FactoryBot.create(:api_token) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_lead_provider_api_token_revoked_event!(author:, api_token:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          heading: "An API token was revoked for lead provider: #{api_token.lead_provider.name}",
          lead_provider: api_token.lead_provider,
          event_type: :lead_provider_api_token_revoked,
          happened_at: Time.zone.now,
          metadata: { description: api_token.description },
          **author_params
        )
      end
    end
  end

  describe '.record_statement_adjustment_added_event!' do
    let(:statement) { FactoryBot.create(:statement) }
    let(:statement_adjustment) { FactoryBot.create(:statement_adjustment, statement:) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_statement_adjustment_added_event!(author:, statement_adjustment:)
        metadata = {
          payment_type: statement_adjustment.payment_type,
          amount: statement_adjustment.amount,
        }

        expect(RecordEventJob).to have_received(:perform_later).with(
          heading: "Statement adjustment added: #{statement_adjustment.payment_type}",
          statement:,
          statement_adjustment:,
          active_lead_provider: statement.active_lead_provider,
          lead_provider: statement.active_lead_provider.lead_provider,
          event_type: :statement_adjustment_added,
          happened_at: Time.zone.now,
          metadata:,
          **author_params
        )
      end
    end
  end

  context "when the event author is a lead provider" do
    let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
    let(:author_params) { { author_name: lead_provider.name, author_type: 'lead_provider_api' } }

    describe '.record_school_partnership_created_event!' do
      let(:school_partnership) { FactoryBot.create(:school_partnership) }
      let(:lead_provider) { school_partnership.lead_provider }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_school_partnership_created_event!(author:, school_partnership:)
          metadata = {
            contract_period_year: school_partnership.contract_period.year,
          }

          expect(RecordEventJob).to have_received(:perform_later).with(
            heading: "#{school_partnership.school.name} partnered with #{school_partnership.delivery_partner.name} (via #{school_partnership.lead_provider.name}) for #{school_partnership.contract_period.year}",
            school_partnership:,
            school: school_partnership.school,
            delivery_partner: school_partnership.delivery_partner,
            lead_provider: school_partnership.lead_provider,
            event_type: :school_partnership_created,
            happened_at: Time.zone.now,
            metadata:,
            **author_params
          )
        end
      end
    end

    describe '.record_school_partnership_updated_event!' do
      let(:school_partnership) { FactoryBot.create(:school_partnership) }
      let(:lead_provider) { school_partnership.lead_provider }
      let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
      let(:author_params) { { author_name: lead_provider.name, author_type: 'lead_provider_api' } }

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          previous_delivery_partner = school_partnership.delivery_partner
          school_partnership.update!(lead_provider_delivery_partnership: FactoryBot.create(:lead_provider_delivery_partnership))
          Events::Record.record_school_partnership_updated_event!(author:, school_partnership:, previous_delivery_partner:, modifications: school_partnership.saved_changes)
          metadata = {
            contract_period_year: school_partnership.contract_period.year,
          }

          expect(RecordEventJob).to have_received(:perform_later).with(
            heading: "#{school_partnership.school.name} changed partnership from #{previous_delivery_partner.name} to #{school_partnership.delivery_partner.name} (via #{school_partnership.lead_provider.name}) for #{school_partnership.contract_period.year}",
            school_partnership:,
            school: school_partnership.school,
            delivery_partner: school_partnership.delivery_partner,
            lead_provider: school_partnership.lead_provider,
            event_type: :school_partnership_updated,
            happened_at: Time.zone.now,
            metadata:,
            modifications: [/Lead provider delivery partnership changed from '\d+' to '\d+'/],
            **author_params
          )
        end
      end
    end
  end

  describe '.record_statement_adjustment_updated_event!' do
    let(:statement) { FactoryBot.create(:statement) }
    let(:statement_adjustment) { FactoryBot.create(:statement_adjustment, statement:) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_statement_adjustment_updated_event!(author:, statement_adjustment:)
        metadata = {
          payment_type: statement_adjustment.payment_type,
          amount: statement_adjustment.amount,
        }

        expect(RecordEventJob).to have_received(:perform_later).with(
          heading: "Statement adjustment updated: #{statement_adjustment.payment_type}",
          statement:,
          statement_adjustment:,
          active_lead_provider: statement.active_lead_provider,
          lead_provider: statement.active_lead_provider.lead_provider,
          event_type: :statement_adjustment_updated,
          happened_at: Time.zone.now,
          metadata:,
          **author_params
        )
      end
    end
  end

  describe '.record_statement_adjustment_deleted_event!' do
    let(:statement) { FactoryBot.create(:statement) }
    let(:statement_adjustment) { FactoryBot.create(:statement_adjustment, statement:) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_statement_adjustment_deleted_event!(author:, statement_adjustment:)
        metadata = {
          payment_type: statement_adjustment.payment_type,
          amount: statement_adjustment.amount,
        }

        expect(RecordEventJob).to have_received(:perform_later).with(
          heading: "Statement adjustment deleted: #{statement_adjustment.payment_type}",
          statement:,
          active_lead_provider: statement.active_lead_provider,
          lead_provider: statement.active_lead_provider.lead_provider,
          event_type: :statement_adjustment_deleted,
          happened_at: Time.zone.now,
          metadata:,
          **author_params
        )
      end
    end
  end

  describe '.record_statement_authorised_for_payment_event!' do
    let(:statement) { FactoryBot.create(:statement) }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        statement.update!(marked_as_paid_at: Time.zone.now)

        Events::Record.record_statement_authorised_for_payment_event!(
          author:,
          statement:,
          happened_at: statement.marked_as_paid_at
        )

        expect(RecordEventJob).to have_received(:perform_later).with(
          heading: "Statement authorised for payment",
          event_type: :statement_authorised_for_payment,
          statement:,
          active_lead_provider: statement.active_lead_provider,
          lead_provider: statement.active_lead_provider.lead_provider,
          happened_at: statement.marked_as_paid_at,
          metadata: hash_including(
            contract_period_year: statement.active_lead_provider.contract_period.year
          ),
          **author_params
        )
      end
    end
  end

  describe '#record_lead_provider_delivery_partnership_added_event!' do
    let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
    let(:lead_provider_delivery_partnership) do
      FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider:)
    end

    it 'records the event with correct attributes' do
      event_record_double = instance_double(Events::Record)
      allow(Events::Record).to receive(:new).and_return(event_record_double)
      expect(event_record_double).to receive(:record_event!)

      Events::Record.record_lead_provider_delivery_partnership_added_event!(
        author:,
        delivery_partner:,
        lead_provider:,
        contract_period:,
        lead_provider_delivery_partnership:
      )
    end

    it 'creates an event with the correct heading' do
      event_record = Events::Record.new(
        author:,
        event_type: :lead_provider_delivery_partnership_added,
        heading: "#{lead_provider.name} partnered with #{delivery_partner.name} for #{contract_period.year}",
        delivery_partner:,
        lead_provider:,
        lead_provider_delivery_partnership:,
        happened_at: anything
      )

      allow(Events::Record).to receive(:new).with(
        event_type: :lead_provider_delivery_partnership_added,
        author:,
        heading: "#{lead_provider.name} partnered with #{delivery_partner.name} for #{contract_period.year}",
        delivery_partner:,
        lead_provider:,
        lead_provider_delivery_partnership:,
        happened_at: anything
      ).and_return(event_record)

      expect(Events::Record).to receive(:new)
      allow(event_record).to receive(:record_event!)

      Events::Record.record_lead_provider_delivery_partnership_added_event!(
        author:,
        delivery_partner:,
        lead_provider:,
        contract_period:,
        lead_provider_delivery_partnership:
      )
    end
  end

  describe '#record_teacher_schedule_assigned_to_training_period!' do
    let(:school) { FactoryBot.create(:school) }
    let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Ichigo', trs_last_name: 'Kurosaki') }
    let(:contract_period) { FactoryBot.create(:contract_period, :with_schedules, year: 2025) }

    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
    let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, contract_period:) }
    let(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }
    let(:started_on) { Date.new(2025, 9, 1) }

    context 'when ECT training' do
      let(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school:,
          started_on:
        )
      end

      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period:, started_on:, school_partnership:) }

      it 'queues a RecordEventJob with the correct values' do
        travel_to(started_on) do
          Events::Record.record_teacher_schedule_assigned_to_training_period!(
            author:,
            training_period:,
            teacher:,
            schedule: training_period.schedule
          )

          expect(RecordEventJob).to have_received(:perform_later).with(
            training_period:,
            teacher:,
            schedule: training_period.schedule,
            heading: "Ichigo Kurosaki’s ECT training period schedule was set to ecf-standard-september for 2025",
            event_type: :teacher_schedule_assigned_to_training_period,
            happened_at: Time.zone.now,
            **author_params
          )
        end
      end
    end

    context 'when Mentor training' do
      let(:mentor_at_school_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          school:,
          started_on:
        )
      end

      let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:, started_on:, school_partnership:) }

      it 'queues a RecordEventJob with the correct values' do
        travel_to(started_on) do
          Events::Record.record_teacher_schedule_assigned_to_training_period!(
            author:,
            training_period:,
            teacher:,
            schedule: training_period.schedule
          )

          expect(RecordEventJob).to have_received(:perform_later).with(
            training_period:,
            teacher:,
            schedule: training_period.schedule,
            heading: "Ichigo Kurosaki’s mentor training period schedule was set to ecf-standard-september for 2025",
            event_type: :teacher_schedule_assigned_to_training_period,
            happened_at: Time.zone.now,
            **author_params
          )
        end
      end
    end
  end

  describe '.record_training_period_assigned_to_school_partnership_event!' do
    let(:school) { FactoryBot.create(:school) }
    let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Ichigo', trs_last_name: 'Kurosaki') }
    let(:school_partnership) { FactoryBot.create(:school_partnership, school:) }
    let(:lead_provider) { school_partnership.lead_provider }
    let(:delivery_partner) { school_partnership.delivery_partner }

    context 'when ECT training' do
      let(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school:,
          started_on: Date.new(2025, 1, 1),
          finished_on: Date.new(2025, 12, 31)
        )
      end

      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :with_only_expression_of_interest,
          ect_at_school_period:,
          started_on: Date.new(2025, 3, 1),
          finished_on: Date.new(2025, 3, 31)
        )
      end

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_training_period_assigned_to_school_partnership_event!(
            author:,
            school_partnership:,
            training_period:,
            ect_at_school_period:,
            teacher:,
            lead_provider:,
            delivery_partner:,
            school:,
            mentor_at_school_period: nil
          )

          expect(RecordEventJob).to have_received(:perform_later).with(
            school_partnership:,
            training_period:,
            ect_at_school_period:,
            teacher:,
            lead_provider:,
            delivery_partner:,
            school:,
            heading: "Ichigo Kurosaki’s ECT training period was assigned to a school partnership",
            event_type: :training_period_assigned_to_school_partnership,
            happened_at: Time.zone.now,
            **author_params
          )
        end
      end
    end

    context 'when mentor training' do
      let(:mentor_at_school_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          school:,
          started_on: Date.new(2025, 1, 1),
          finished_on: Date.new(2025, 12, 31)
        )
      end

      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_mentor,
          :with_only_expression_of_interest,
          mentor_at_school_period:,
          started_on: Date.new(2025, 3, 1),
          finished_on: Date.new(2025, 3, 31)
        )
      end

      it 'queues a RecordEventJob with the correct values' do
        freeze_time do
          Events::Record.record_training_period_assigned_to_school_partnership_event!(
            author:,
            school_partnership:,
            training_period:,
            mentor_at_school_period:,
            teacher:,
            lead_provider:,
            delivery_partner:,
            school:,
            ect_at_school_period: nil
          )

          expect(RecordEventJob).to have_received(:perform_later).with(
            school_partnership:,
            training_period:,
            mentor_at_school_period:,
            teacher:,
            lead_provider:,
            delivery_partner:,
            school:,
            heading: "Ichigo Kurosaki’s mentor training period was assigned to a school partnership",
            event_type: :training_period_assigned_to_school_partnership,
            happened_at: Time.zone.now,
            **author_params
          )
        end
      end
    end
  end

  describe '.record_dfe_user_created_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_dfe_user_created_event!(author:, user: another_dfe_user, modifications: another_dfe_user.changes)

        expect(RecordEventJob).to have_received(:perform_later).with(
          hash_including(
            user: another_dfe_user,
            modifications: anything,
            metadata: another_dfe_user.changes,
            happened_at: Time.zone.now,
            heading: "User Ian Richardson added",
            event_type: :dfe_user_created,
            **author_params
          )
        )
      end
    end
  end

  describe '.record_dfe_user_updated_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        another_dfe_user.name = "Ian William Richardson"
        Events::Record.record_dfe_user_updated_event!(author:, user: another_dfe_user, modifications: another_dfe_user.changes)

        expect(RecordEventJob).to have_received(:perform_later).with(
          hash_including(
            user: another_dfe_user,
            modifications: anything,
            metadata: another_dfe_user.changes,
            heading: "User Ian William Richardson updated",
            happened_at: Time.zone.now,
            event_type: :dfe_user_updated,
            **author_params
          )
        )
      end
    end
  end

  describe '.record_teacher_set_funding_eligibility_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        teacher.mentor_first_became_eligible_for_training_at = Time.zone.now
        raw_modifications = teacher.changes

        Events::Record.record_teacher_set_funding_eligibility_event!(author:, teacher:, happened_at:, modifications: raw_modifications)

        expect(RecordEventJob).to have_received(:perform_later).with(
          hash_including(
            **author_params,
            event_type: :teacher_funding_eligibility_set,
            happened_at:,
            heading: "Rhys Ifans's funding eligibility was set",
            metadata: raw_modifications,
            modifications: ["Mentor first became eligible for training at set to '#{Time.zone.now}'"],
            teacher:
          )
        )
      end
    end
  end
end
