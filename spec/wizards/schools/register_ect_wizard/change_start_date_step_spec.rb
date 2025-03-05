RSpec.describe Schools::RegisterECTWizard::ChangeStartDateStep, type: :model do
  subject { described_class.new(start_date: { 1 => "2025", 2 => "01" }) }

  describe "inheritance" do
    it "inherits from StartDateStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::StartDateStep)
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
