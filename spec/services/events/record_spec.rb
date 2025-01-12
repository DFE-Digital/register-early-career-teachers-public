describe Events::Record do
  let(:user) { FactoryBot.create(:user, name: 'Christopher Biggins', email: 'christopher.biggins@education.gov.uk') }
  let(:teacher) { FactoryBot.build(:teacher, first_name: 'Rhys', last_name: 'Ifans') }
  let(:induction_period) { FactoryBot.build(:induction_period) }
  let(:appropriate_body) { FactoryBot.build(:appropriate_body, name: "Burns Slant Drilling Co.") }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:author_params) { { author_id: author.id, author_name: author.name, author_email: author.email, author_type: :dfe_staff_user } }

  before { allow(RecordEventJob).to receive(:perform_later).and_return(true) }

  describe '#initialize' do
    let(:heading) { 'Something happened' }
    let(:event_type) { :appropriate_body_claims_teacher }
    let(:body) { 'A very important event' }
    let(:happened_at) { 2.minutes.ago }

    context "when the user isn't a Sessions::User" do
      let(:non_session_user) { FactoryBot.build(:user) }

      it 'fails with a AuthorNotASessionsUser error with a non Sessions::User author' do
        expect {
          Events::Record.new(author: non_session_user, event_type:, heading:, body:, happened_at:)
        }.to raise_error(Events::AuthorNotASessionsUser)
      end
    end

    it 'assigns and saves attributes correctly' do
      attributes = {
        author:,
        event_type:,
        heading:,
        body:,
        happened_at:,
        induction_period:,
        teacher:,
        school: FactoryBot.build(:school),
        appropriate_body: FactoryBot.build(:appropriate_body),
        induction_extension: FactoryBot.build(:induction_extension),
        ect_at_school_period: FactoryBot.build(:ect_at_school_period),
        mentor_at_school_period: FactoryBot.build(:mentor_at_school_period),
        training_period: FactoryBot.build(:training_period),
        mentorship_period: FactoryBot.build(:mentorship_period),
        provider_partnership: FactoryBot.build(:provider_partnership),
        lead_provider: FactoryBot.build(:lead_provider),
        delivery_partner: FactoryBot.build(:delivery_partner),
        user: FactoryBot.build(:user),
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
end
