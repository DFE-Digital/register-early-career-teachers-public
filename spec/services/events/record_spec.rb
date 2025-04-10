RSpec.describe Events::Record do
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

  before { allow(RecordEventJob).to receive(:perform_later).and_return(true) }

  describe '#initialize' do
    context "when the user isn't a Sessions::User" do
      let(:non_session_user) { FactoryBot.build(:user) }

      it 'fails with a AuthorNotASessionsUser error with a non Sessions::User author' do
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
        provider_partnership: FactoryBot.create(:provider_partnership),
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
      provider_partnership: FactoryBot.build(:provider_partnership),
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

  describe '.record_appropriate_body_passes_teacher_event' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_appropriate_body_passes_teacher_event(author:, teacher:, appropriate_body:, induction_period:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_period:,
          teacher:,
          appropriate_body:,
          heading: 'Rhys Ifans passed induction',
          event_type: :appropriate_body_passes_teacher,
          happened_at: induction_period.finished_on,
          **author_params
        )
      end
    end

    it 'fails when induction period is missing' do
      expect {
        Events::Record.record_appropriate_body_fails_teacher_event(author:, teacher:, appropriate_body:, induction_period: nil)
      }.to raise_error(Events::NoInductionPeriod)
    end
  end

  describe '.record_appropriate_body_fails_teacher_event' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_appropriate_body_fails_teacher_event(author:, teacher:, appropriate_body:, induction_period:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_period:,
          teacher:,
          appropriate_body:,
          heading: 'Rhys Ifans failed induction',
          event_type: :appropriate_body_fails_teacher,
          happened_at: induction_period.finished_on,
          **author_params
        )
      end
    end

    it 'fails when induction period is missing' do
      expect {
        Events::Record.record_appropriate_body_fails_teacher_event(author:, teacher:, appropriate_body:, induction_period: nil)
      }.to raise_error(Events::NoInductionPeriod)
    end
  end

  describe '.record_induction_period_deleted!' do
    let(:raw_modifications) { { 'id' => 1, 'teacher_id' => teacher.id, 'appropriate_body_id' => appropriate_body.id } }

    context 'when induction status was reset on TRS' do
      it 'queues a RecordEventJob with the correct values including body' do
        freeze_time do
          Events::Record.record_induction_period_deleted!(
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
          Events::Record.record_induction_period_deleted!(
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

  describe '.record_appropriate_body_adds_induction_extension_event' do
    let(:induction_extension) { FactoryBot.build(:induction_extension) }

    it 'queues a RecordEventJob with the correct values' do
      raw_modifications = induction_extension.changes
      induction_extension.save!

      freeze_time do
        Events::Record.record_appropriate_body_adds_induction_extension_event(author:, teacher:, appropriate_body:, induction_extension:, modifications: raw_modifications)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_extension:,
          teacher:,
          appropriate_body:,
          heading: "Rhys Ifans's induction extended by 1.2 terms",
          event_type: :appropriate_body_adds_induction_extension,
          happened_at: Time.zone.now,
          modifications: ["Number of terms set to '1.2'"],
          metadata: raw_modifications,
          **author_params
        )
      end
    end
  end

  describe '.record_appropriate_body_updates_induction_extension_event' do
    let(:induction_extension) { FactoryBot.create(:induction_extension) }

    it 'queues a RecordEventJob with the correct values' do
      induction_extension.assign_attributes(number_of_terms: 3.2)
      raw_modifications = induction_extension.changes

      freeze_time do
        Events::Record.record_appropriate_body_updates_induction_extension_event(author:, teacher:, appropriate_body:, induction_extension:, modifications: raw_modifications)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_extension:,
          teacher:,
          appropriate_body:,
          heading: "Rhys Ifans's induction extended by 3.2 terms",
          event_type: :appropriate_body_updates_induction_extension,
          happened_at: Time.zone.now,
          modifications: ["Number of terms changed from '1.2' to '3.2'"],
          metadata: raw_modifications,
          **author_params
        )
      end
    end
  end

  describe '.record_admin_updates_induction_period!' do
    let(:three_weeks_ago) { 3.weeks.ago.to_date }
    let(:two_weeks_ago) { 2.weeks.ago.to_date }
    let(:induction_period) { FactoryBot.create(:induction_period, :active, started_on: three_weeks_ago) }

    it 'queues a RecordEventJob with the correct values' do
      induction_period.assign_attributes(started_on: two_weeks_ago)
      raw_modifications = induction_period.changes

      freeze_time do
        Events::Record.record_admin_updates_induction_period!(author:, teacher:, appropriate_body:, induction_period:, modifications: raw_modifications)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_period:,
          teacher:,
          appropriate_body:,
          heading: 'Induction period updated by admin',
          event_type: :admin_updates_induction_period,
          happened_at: Time.zone.now,
          modifications: ["Started on changed from '#{3.weeks.ago.to_date.to_formatted_s(:govuk_short)}' to '#{2.weeks.ago.to_date.to_formatted_s(:govuk_short)}'"],
          metadata: raw_modifications,
          **author_params
        )
      end
    end
  end

  describe '.teacher_name_changed_in_trs!' do
    let(:old_name) { 'Wilfred Bramble' }
    let(:new_name) { 'Willy Brambs' }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.teacher_name_changed_in_trs!(author:, teacher:, appropriate_body:, old_name:, new_name:)

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

  describe '.teacher_induction_status_changed_in_trs!' do
    let(:old_induction_status) { 'InProgress' }
    let(:new_induction_status) { 'Exempt' }

    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.teacher_induction_status_changed_in_trs!(author:, teacher:, appropriate_body:, old_induction_status:, new_induction_status:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          appropriate_body:,
          heading: "Induction status changed from 'InProgress' to 'Exempt'",
          event_type: :teacher_induction_status_updated_by_trs,
          happened_at: Time.zone.now,
          **author_params
        )
      end
    end
  end

  describe '.teacher_imported_from_trs!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.teacher_imported_from_trs!(author:, teacher:, appropriate_body:)

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

  describe '.teacher_attributes_updated_from_trs!' do
    it 'queues a RecordEventJob with the correct values' do
      teacher.assign_attributes(trs_first_name: 'Otto', trs_last_name: 'Hightower')
      modifications = teacher.changes
      freeze_time do
        Events::Record.teacher_attributes_updated_from_trs!(author:, teacher:, modifications:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          teacher:,
          heading: "TRS attributes updated",
          event_type: :teacher_attributes_updated_from_trs,
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

  describe 'teacher_induction_status_reset event' do
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
end
