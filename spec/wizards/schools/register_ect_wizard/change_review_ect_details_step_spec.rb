RSpec.describe Schools::RegisterECTWizard::ChangeReviewECTDetailsStep, type: :model do
  subject { described_class.new(change_name: "yes", corrected_name: "Jane Smith") }

  describe "inheritance" do
    it "inherits from ReviewECTDetailsStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::ReviewECTDetailsStep)
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
