describe Events::Record do
  describe '#initialize' do
    let(:user) { FactoryBot.create(:user, name: 'Christopher Biggins', email: 'christopher.biggins@education.gov.uk') }
    let!(:session_user) do
      Sessions::Users::DfEPersona.new(email: user.email)
    end

    let(:heading) { 'Something happened' }
    let(:event_type) { :appropriate_body_claims_teacher }
    let(:body) { 'A very important event' }
    let(:happened_at) { 2.minutes.ago }
    let(:author) { session_user }

    context "when the user isn't a Sessions::User" do
      let(:non_session_user) { FactoryBot.build(:user) }

      it 'fails with a NotASessionsUser error with a non Sessions::User author' do
        expect {
          Events::Record.new(author: non_session_user, event_type:, heading:, body:, happened_at:)
        }.to raise_error(Events::NotASessionsUser)
      end
    end

    it 'assigns and saves attributes correctly' do
      attributes = {
        author:,
        event_type:,
        heading:,
        body:,
        happened_at:,
        school: FactoryBot.build(:school),
        induction_period: FactoryBot.build(:induction_period),
        teacher: FactoryBot.build(:teacher),
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

      allow(Event).to receive(:create!).and_return(true)

      event_record.record_event!

      expect(Event).to have_received(:create!).with(
        **author.event_author_params,
        **attributes.except(:author)
      )
    end
  end
end
