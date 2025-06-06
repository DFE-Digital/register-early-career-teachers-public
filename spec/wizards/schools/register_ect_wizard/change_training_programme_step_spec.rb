RSpec.describe Schools::RegisterECTWizard::ChangeTrainingProgrammeStep, type: :model do
  subject { described_class.new(wizard:, training_programme: new_training_programme) }

  let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }
  let(:training_programme) { 'school_led' }
  let(:new_training_programme) { 'provider_led' }
  let(:school) { FactoryBot.create(:school, :independent) }
  let(:store) { FactoryBot.build(:session_repository, training_programme:, lead_provider_id:) }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :change_training_programme, store:, school:) }

  describe "inheritance" do
    it "inherits from TrainingProgrammeStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::TrainingProgrammeStep)
    end
  end

  describe "#next_step" do
    before { subject.send(:persist) }

    context 'when the training programme is school led' do
      let(:new_training_programme) { 'school_led' }

      it { expect(subject.next_step).to eq(:check_answers) }
    end

    context 'when the training programme is provided led' do
      let(:new_training_programme) { 'provider_led' }

      context 'when the school has last programme choices' do
        let(:school) { FactoryBot.create(:school, :independent, :teaching_school_hub_ab_last_chosen, :school_led_last_chosen) }

        it { expect(subject.next_step).to eq(:training_programme_change_lead_provider) }
      end

      context 'when it has changed from school led' do
        let(:training_programme) { 'school_led' }

        it { expect(subject.next_step).to eq(:training_programme_change_lead_provider) }
      end

      context 'when a lead provider has not been selected yet' do
        let(:lead_provider_id) { nil }

        it { expect(subject.next_step).to eq(:training_programme_change_lead_provider) }
      end

      context 'when a lead provider has already been selected' do
        let(:training_programme) { 'provider_led' }
        let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }

        it { expect(subject.next_step).to eq(:check_answers) }
      end
    end
  end

  describe "#previous_step" do
    before { subject.send(:persist) }

    context 'when the training programme is school led' do
      let(:training_programme) { 'school_led' }

      it { expect(subject.previous_step).to eq(:check_answers) }
    end

    context 'when the training programme is provided led' do
      let(:new_training_programme) { 'provider_led' }

      context 'when a lead provider has not been selected yet' do
        let(:lead_provider_id) { nil }

        it { expect(subject.previous_step).to eq(:training_programme_change_lead_provider) }
      end

      context 'when a lead provider has already been selected' do
        it { expect(subject.previous_step).to eq(:check_answers) }
      end
    end
  end
end
