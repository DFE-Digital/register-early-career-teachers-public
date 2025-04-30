RSpec.describe Schools::RegisterECTWizard::PreviousECTDetailsStep, type: :model do
  subject(:previous_ect_details_step) { described_class.new }

  describe '#next_step' do
    it 'returns the email_address step as the next step in the flow' do
      expect(previous_ect_details_step.next_step).to eq(:email_address)
    end
  end

  describe '#previous_step' do
    it 'returns the review_ect_details step as the previous step in the flow' do
      expect(previous_ect_details_step.previous_step).to eq(:review_ect_details)
    end
  end
end
