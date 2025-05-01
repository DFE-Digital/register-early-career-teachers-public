RSpec.describe Schools::RegisterECTWizard::ChangeStateSchoolAppropriateBodyStep, type: :model do
  subject { described_class.new(wizard:, appropriate_body_id: '123') }

  let(:school) { FactoryBot.create(:school, :state_funded, :teaching_school_hub_ab_chosen, :school_led_chosen) }
  let(:wizard) do
    FactoryBot.build(:register_ect_wizard, current_step: :change_state_school_appropriate_body, school:)
  end

  describe "inheritance" do
    it "inherits from StateSchoolAppropriateBodyStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::StateSchoolAppropriateBodyStep)
    end
  end

  describe "#next_step" do
    it { expect(subject.next_step).to eq(:check_answers) }
  end

  describe "#previous_step" do
    it { expect(subject.previous_step).to eq(:check_answers) }
  end
end
