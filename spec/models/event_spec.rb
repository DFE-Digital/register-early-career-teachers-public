describe Event do
  describe 'associations' do
    it { is_expected.to belong_to(:teacher).optional }
    it { is_expected.to belong_to(:appropriate_body).optional }
    it { is_expected.to belong_to(:induction_period).optional }
    it { is_expected.to belong_to(:induction_extension).optional }

    it { is_expected.to belong_to(:school).optional }
    it { is_expected.to belong_to(:ect_at_school_period).optional }
    it { is_expected.to belong_to(:mentor_at_school_period).optional }
    it { is_expected.to belong_to(:training_period).optional }
    it { is_expected.to belong_to(:mentorship_period).optional }
    it { is_expected.to belong_to(:provider_partnership).optional }
    it { is_expected.to belong_to(:lead_provider).optional }
    it { is_expected.to belong_to(:delivery_partner).optional }
    it { is_expected.to belong_to(:user).optional }

    it { is_expected.to belong_to(:author).class_name('User').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:heading) }
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_inclusion_of(:event_type).in_array(Event::EVENT_TYPES) }

    describe '#check_author_present' do
      context 'when author_id and author_email are missing' do
        subject { FactoryBot.build(:event, author_email: nil, author_name: nil, author_id: nil) }

        it { is_expected.to be_invalid }

        it 'states the author is missing in the email' do
          subject.valid?
          expect(subject.errors.messages[:base]).to include('Author is missing')
        end
      end
    end
  end

  describe '#happened_at' do
    it { is_expected.to validate_presence_of(:happened_at) }

    describe '#event_happened_in_the_past' do
      subject { FactoryBot.build(:event, happened_at:) }
      before { subject.valid? }

      context 'when happened_at is in the past' do
        let(:happened_at) { 1.minute.from_now }

        it { is_expected.to(be_invalid) }

        it 'has a validation error' do
          expect(subject.errors.messages[:happened_at]).to include('Event must have already happened')
        end
      end

      context 'when happened_at is in the future' do
        let(:happened_at) { 1.minute.ago }

        it { is_expected.to(be_valid) }
      end
    end
  end
end
