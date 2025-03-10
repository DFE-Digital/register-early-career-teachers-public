describe Events::Record do
  let(:user) { FactoryBot.create(:user, name: 'Christopher Biggins', email: 'christopher.biggins@education.gov.uk') }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Rhys', trs_last_name: 'Ifans') }
  let(:induction_period) { FactoryBot.create(:induction_period) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Burns Slant Drilling Co.") }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:author_params) { { author_id: author.id, author_name: author.name, author_email: author.email, author_type: :dfe_staff_user } }

  let(:heading) { 'Something happened' }
  let(:event_type) { :appropriate_body_claims_teacher }
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
        let(:attributes_with_unsaved_school) { { attribute => object } }
        subject { Events::Record.new(author:, event_type:, heading:, happened_at:, **attributes_with_unsaved_school) }

        it 'fails with a NotPersistedRecordError' do
          expect { subject.record_event! }.to raise_error(Events::NotPersistedRecord, attribute.to_s)
        end
      end
    end
  end

  describe '.record_appropriate_body_claims_teacher_event!' do
    it 'queues a RecordEventJob with the correct values' do
      freeze_time do
        Events::Record.record_appropriate_body_claims_teacher_event!(author:, teacher:, appropriate_body:, induction_period:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          induction_period:,
          teacher:,
          appropriate_body:,
          heading: 'Rhys Ifans was claimed by Burns Slant Drilling Co.',
          event_type: :appropriate_body_claims_teacher,
          happened_at: Time.zone.now,
          **author_params
        )
      end
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
          happened_at: Time.zone.now,
          **author_params
        )
      end
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
          happened_at: Time.zone.now,
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

  describe '.teacher_name_changed_in_trs' do
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
end
