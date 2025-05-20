RSpec.describe Schools::RegisterECTWizard::NoPreviousECTChoicesChangeProgrammeTypeStep, type: :model do
  subject { described_class.new(wizard:, programme_type: new_programme_type) }

  let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }
  let(:programme_type) { 'school_led' }
  let(:new_programme_type) { 'provider_led' }
  let(:independent_school) { FactoryBot.create(:school, :independent) }
  let(:state_funded_school) { FactoryBot.create(:school, :state_funded) }
  let(:school) { independent_school }
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

      it { expect(subject.next_step).to eq(:no_previous_ect_choices_change_lead_provider) }
    end
  end

  describe "#previous_step" do
    before { subject.send(:persist) }

    context 'when the programme type is school led' do
      let(:programme_type) { 'school_led' }

      context 'when the school is state funded' do
        let(:school) { state_funded_school }

        it { expect(subject.previous_step).to eq(:no_previous_ect_choices_change_state_school_appropriate_body) }
      end

      context 'when the school is independent' do
        let(:school) { independent_school }

        it { expect(subject.previous_step).to eq(:no_previous_ect_choices_change_independent_school_appropriate_body) }
      end
    end

    context 'when the programme type is provided led' do
      let(:programme_type) { 'provider_led' }

      context 'when the lead provider has already been selected' do
        context 'when the school is state funded' do
          let(:school) { state_funded_school }

          it { expect(subject.previous_step).to eq(:no_previous_ect_choices_change_state_school_appropriate_body) }
        end

        context 'when the school is independent' do
          let(:school) { independent_school }

          it { expect(subject.previous_step).to eq(:no_previous_ect_choices_change_independent_school_appropriate_body) }
        end
      end

      context 'when the lead provider has not been selected yet' do
        let(:lead_provider_id) { nil }

        it { expect(subject.previous_step).to eq(:no_previous_ect_choices_change_lead_provider) }
      end
    end
  end
end
