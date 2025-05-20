RSpec.describe Schools::RegisterECTWizard::ChangeUsePreviousECTChoicesStep, type: :model do
  subject { described_class.new(wizard:, use_previous_ect_choices: new_use_previous_ect_choices) }

  let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }
  let(:use_previous_ect_choices) { false }
  let(:new_use_previous_ect_choices) { false }
  let(:programme_type) { 'school_led' }
  let(:school) { FactoryBot.create(:school, :independent, :teaching_school_hub_ab_chosen, :school_led_chosen) }
  let(:store) { FactoryBot.build(:session_repository, use_previous_ect_choices:, programme_type:, lead_provider_id:) }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :change_use_previous_ect_choices, store:, school:) }

  describe "inheritance" do
    it "inherits from UsePreviousECTChoicesStep" do
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

      context 'when the school is independent' do
        let(:school) { FactoryBot.create(:school, :independent, :teaching_school_hub_ab_chosen, :school_led_chosen) }

        it { expect(subject.next_step).to eq(:no_previous_ect_choices_change_independent_school_appropriate_body) }
      end

      context 'when the school is state funded' do
        let(:school) { FactoryBot.create(:school, :state_funded, :teaching_school_hub_ab_chosen, :school_led_chosen) }

        it { expect(subject.next_step).to eq(:no_previous_ect_choices_change_state_school_appropriate_body) }
      end
    end
  end

  describe "#previous_step" do
    it { expect(subject.previous_step).to eq(:check_answers) }
  end
end
