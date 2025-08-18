RSpec.describe Schools::AssignExistingMentorWizard::Wizard do
  describe '.step?' do
    it 'returns true for a valid step name' do
      expect(described_class.step?(:confirmation)).to be(true)
    end

    it 'returns false for an invalid step name' do
      expect(described_class.step?(:fake_step)).to be(false)
    end
  end

  describe '#allowed_step?' do
    let(:wizard) do
      described_class.new(
        current_step: :review_mentor_eligibility,
        store: instance_double(SessionRepository),
        mentor_period_id: 1,
        ect_id: 2,
        author: instance_double(User)
      )
    end

    it 'returns true for allowed steps' do
      expect(wizard.allowed_step?(:review_mentor_eligibility)).to be(true)
    end

    it 'returns false for an unlisted step' do
      expect(wizard.allowed_step?(:some_other_step)).to be(false)
    end
  end
end
