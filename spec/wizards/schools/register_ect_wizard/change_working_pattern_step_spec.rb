RSpec.describe Schools::RegisterECTWizard::ChangeWorkingPatternStep, type: :model do
  subject { described_class.new(working_pattern: 'full_time') }

  describe "inheritance" do
    it "inherits from WorkingPatternStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::WorkingPatternStep)
    end
  end

  describe "#next_step" do
    it "returns :check_answers" do
      expect(subject.next_step).to eq(:check_answers)
    end
  end
end
