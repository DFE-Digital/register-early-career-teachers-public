RSpec.describe Schools::RegisterECTWizard::ChangeIndependentSchoolAppropriateBodyStep, type: :model do
  subject { described_class.new(appropriate_body_id: '123', appropriate_body_type: 'Some Teaching School Hub') }

  describe "inheritance" do
    it "inherits from IndependentSchoolAppropriateBodyStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::IndependentSchoolAppropriateBodyStep)
    end
  end

  describe "#next_step" do
    it "returns :check_answers" do
      expect(subject.next_step).to eq(:check_answers)
    end
  end
end
