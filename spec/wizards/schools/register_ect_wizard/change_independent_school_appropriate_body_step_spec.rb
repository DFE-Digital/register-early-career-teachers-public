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
    context 'when the school has programme choices' do
      let(:school) { FactoryBot.create(:school, :independent, :teaching_induction_panel_chosen, :school_led_chosen) }

      it { expect(subject.next_step).to eq(:change_programme_type) }
    end

    context 'when the school has no programme choices' do
      it { expect(subject.next_step).to eq(:check_answers) }
    end
  end

  describe "#previous_step" do
    context 'when the school has programme choices' do
      let(:school) { FactoryBot.create(:school, :independent, :teaching_induction_panel_chosen, :school_led_chosen) }

      it { expect(subject.previous_step).to eq(:change_use_previous_ect_choices) }
    end

    context 'when the school has no programme choices' do
      it { expect(subject.previous_step).to eq(:check_answers) }
    end
  end
end
