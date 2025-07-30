RSpec.describe Events::Record do
  include ActiveJob::TestHelper

  let(:user) { FactoryBot.create(:user, name: 'Christopher Biggins', email: 'christopher.biggins@education.gov.uk') }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Rhys', trs_last_name: 'Ifans') }
  let(:induction_period) { FactoryBot.create(:induction_period) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Burns Slant Drilling Co.") }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:author_params) { { author_id: author.id, author_name: author.name, author_email: author.email, author_type: :dfe_staff_user } }

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
      ect_at_school_period = FactoryBot.create(:ect_at_school_period, :active, started_on: 3.weeks.ago)
      mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.weeks.ago)

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
        training_period: FactoryBot.create(:training_period, :active, ect_at_school_period:, started_on: 1.week.ago),
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
    let(:induction_period) { FactoryBot.create(:induction_period, :active, started_on: three_weeks_ago) }

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

        Events::Record.record_induction_period_reopened_event!(author:, induction_period:, modifications: raw_modifications, teacher:, appropriate_body:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          induction_period:,
          appropriate_body:,
          heading: 'Induction period reopened',
          event_type: :induction_period_reopened,
          happened_at: Time.zone.now,
          modifications: anything,
          metadata: raw_modifications,
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

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_teacher_registered_as_mentor_event!(author:, teacher:, mentor_at_school_period:, school:, training_period:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          school:,
          training_period:,
          mentor_at_school_period:,
          heading: "Rhys Ifans was registered as a mentor at #{school.name}",
          event_type: :teacher_registered_as_mentor,
          happened_at: Time.zone.now,
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
          happened_at: Time.zone.now,
          **author_params
        )
      end
    end
  end

  describe '.record_teacher_starts_mentoring_event!' do
    let(:started_on_param) { { started_on: 2.years.ago.to_date } }
    let(:school) { FactoryBot.create(:school) }
    let(:mentee) { FactoryBot.create(:teacher, trs_first_name: 'Steffan', trs_last_name: 'Rhodri') }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, teacher: mentee, school:, **started_on_param) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :active, teacher:, school:, **started_on_param) }
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
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, teacher:, school:, **started_on_param) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :active, teacher: mentor, school:, **started_on_param) }
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
      ProcessBatchClaimJob.perform_now(batch, author.email, author.name, SecureRandom.uuid)
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
end
