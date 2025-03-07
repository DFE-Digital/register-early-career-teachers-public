RSpec.describe Schools::RegisterECTWizard::ChangeUsePreviousECTChoicesStep, type: :model do
  let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }
  let(:use_previous_ect_choices) { false }
  let(:new_use_previous_ect_choices) { false }
  let(:school) { FactoryBot.create(:school, :independent, :teaching_school_hub_chosen, :school_led_chosen) }
  let(:store) { FactoryBot.build(:session_repository, use_previous_ect_choices:, lead_provider_id:) }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :change_use_previous_ect_choices, store:, school:) }

  subject { described_class.new(wizard:, use_previous_ect_choices: new_use_previous_ect_choices) }

  describe "inheritance" do
    it "inherits from ProgrammeTypeStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::UsePreviousECTChoicesStep)
    end
  end

  describe "#next_step" do
    before { subject.send(:persist) }

    context 'when using school choices' do
      let(:new_use_previous_ect_choices) { true }

      it { expect(subject.next_step).to eq(:check_answers) }
    end

    context 'when not using school choices' do
      let(:new_use_previous_ect_choices) { false }

      context 'independent school' do
        let(:school) { FactoryBot.create(:school, :independent, :teaching_school_hub_chosen, :school_led_chosen) }

        it { expect(subject.next_step).to eq(:change_independent_school_appropriate_body) }
      end

      context 'state funded school' do
        let(:school) { FactoryBot.create(:school, :state_funded, :teaching_school_hub_chosen, :school_led_chosen) }

        it { expect(subject.next_step).to eq(:change_state_school_appropriate_body) }
      end
    end
  end

  describe "#previous_step" do
    it { expect(subject.previous_step).to eq(:check_answers) }
  end
end
