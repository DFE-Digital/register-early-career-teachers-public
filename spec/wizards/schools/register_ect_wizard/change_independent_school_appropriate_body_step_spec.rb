RSpec.describe Schools::RegisterECTWizard::ChangeIndependentSchoolAppropriateBodyStep, type: :model do
  subject { described_class.new(wizard:, appropriate_body_id: '123', appropriate_body_type: 'Some Teaching School Hub') }

  let(:school) { FactoryBot.create(:school, :independent) }
  let(:wizard) do
    FactoryBot.build(:register_ect_wizard, current_step: :change_independent_school_appropriate_body, school:)
  end

  describe "inheritance" do
    it "inherits from IndependentSchoolAppropriateBodyStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::IndependentSchoolAppropriateBodyStep)
    end
  end

  describe "#next_step" do
    it { expect(subject.next_step).to eq(:check_answers) }
  end

  describe "#previous_step" do
    it { expect(subject.previous_step).to eq(:check_answers) }
  end
end
