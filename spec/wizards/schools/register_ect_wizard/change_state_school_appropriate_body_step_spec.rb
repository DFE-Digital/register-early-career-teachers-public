RSpec.describe Schools::RegisterECTWizard::ChangeStateSchoolAppropriateBodyStep, type: :model do
  subject { described_class.new(appropriate_body_id: '123') }

  describe "inheritance" do
    it "inherits from StateSchoolAppropriateBodyStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::StateSchoolAppropriateBodyStep)
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
