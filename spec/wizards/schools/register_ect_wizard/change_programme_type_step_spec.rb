RSpec.describe Schools::RegisterECTWizard::ChangeProgrammeTypeStep, type: :model do
  subject { described_class.new(programme_type: 'provider_led') }

  describe "inheritance" do
    it "inherits from ProgrammeTypeStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::ProgrammeTypeStep)
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
