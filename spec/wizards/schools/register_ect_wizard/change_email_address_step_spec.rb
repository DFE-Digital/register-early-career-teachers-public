RSpec.describe Schools::RegisterECTWizard::ChangeEmailAddressStep, type: :model do
  subject { described_class.new(email: 'Jane Doe') }

  describe "inheritance" do
    it "inherits from EmailAddressStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::EmailAddressStep)
    end
  end

  describe "#next_step" do
    it "returns :check_answers" do
      expect(subject.next_step).to eq(:check_answers)
    end
  end

  describe "#previous_step" do
    it "returns :check_answers" do
      expect(subject.next_step).to eq(:check_answers)
    end
  end
end
