RSpec.describe Schools::RegisterECTWizard::ChangeProgrammeTypeStep, type: :model do
  subject { described_class.new(wizard:, programme_type: new_programme_type) }

  let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }
  let(:programme_type) { 'school_led' }
  let(:new_programme_type) { 'provider_led' }
  let(:school) { FactoryBot.create(:school, :independent) }
  let(:store) { FactoryBot.build(:session_repository, programme_type:, lead_provider_id:) }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :change_programme_type, store:, school:) }

  describe "inheritance" do
    it "inherits from ProgrammeTypeStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::ProgrammeTypeStep)
    end
  end

  describe "#next_step" do
    before { subject.send(:persist) }

    context 'when the programme type is school led' do
      let(:new_programme_type) { 'school_led' }

      it { expect(subject.next_step).to eq(:check_answers) }
    end

    context 'when the programme type is provided led' do
      let(:new_programme_type) { 'provider_led' }

      context 'when the school has programme choices' do
        let(:school) { FactoryBot.create(:school, :independent, :teaching_school_hub_ab_chosen, :school_led_chosen) }

        it { expect(subject.next_step).to eq(:programme_type_change_lead_provider) }
      end

      context 'when it has changed from school led' do
        let(:programme_type) { 'school_led' }

        it { expect(subject.next_step).to eq(:programme_type_change_lead_provider) }
      end

      context 'when a lead provider has not been selected yet' do
        let(:lead_provider_id) { nil }

        it { expect(subject.next_step).to eq(:programme_type_change_lead_provider) }
      end

      context 'when a lead provider has already been selected' do
        let(:programme_type) { 'provider_led' }
        let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }

        it { expect(subject.next_step).to eq(:check_answers) }
      end
    end
  end

  describe "#previous_step" do
    before { subject.send(:persist) }

    context 'when the programme type is school led' do
      let(:programme_type) { 'school_led' }

      it { expect(subject.previous_step).to eq(:check_answers) }
    end

    context 'when the programme type is provided led' do
      let(:new_programme_type) { 'provider_led' }

      context 'when a lead provider has not been selected yet' do
        let(:lead_provider_id) { nil }

        it { expect(subject.previous_step).to eq(:programme_type_change_lead_provider) }
      end

      context 'when a lead provider has already been selected' do
        it { expect(subject.previous_step).to eq(:check_answers) }
      end
    end
  end
end
