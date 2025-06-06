RSpec.describe Schools::RegisterECTWizard::TrainingProgrammeStep, type: :model do
  let(:school) { FactoryBot.build(:school) }
  let(:store) { FactoryBot.build(:session_repository, training_programme: 'prepopulated_training_programme') }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :training_programme, school:, store:) }

  describe '#initialize' do
    subject { described_class.new(wizard:, **params) }

    let(:training_programme) { 'provided_training_programme' }

    context 'when the training_programme is provided' do
      let(:params) { { training_programme: } }

      it 'populate the instance from it' do
        expect(subject.training_programme).to eq(training_programme)
      end
    end

    context 'when no training_programme is provided' do
      let(:params) { {} }

      it 'populate it from the wizard store' do
        expect(subject.training_programme).to eq('prepopulated_training_programme')
      end
    end
  end

  describe 'validations' do
    subject { described_class.new(training_programme:) }

    context 'when the training_programme is not present' do
      let(:training_programme) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:training_programme]).to include("Select either 'Provider-led' or 'School-led' training")
      end
    end

    context 'when the training_programme is has an unknown value' do
      let(:training_programme) { 'unknown_training_programme' }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:training_programme]).to include("'unknown_training_programme' is not a valid programme type")
      end
    end

    context 'when the training_programme is present and a known value' do
      let(:training_programme) { 'provider_led' }

      it { expect(subject).to be_valid }
    end
  end

  describe 'steps' do
    subject { wizard.current_step }

    describe '#next_step' do
      context 'when training_programme is provider_led' do
        before do
          allow(wizard.ect).to receive(:provider_led?).and_return(true)
        end

        it 'returns the next step' do
          expect(subject.next_step).to eq(:lead_provider)
        end
      end

      context 'when training_programme is school_led' do
        it 'returns the next step' do
          expect(subject.next_step).to eq(:check_answers)
        end
      end
    end

    describe '#previous_step' do
      context 'when the school is independent' do
        let(:school) { FactoryBot.create(:school, :independent) }

        it 'returns :independent_school_appropriate_body' do
          expect(subject.previous_step).to eq(:independent_school_appropriate_body)
        end
      end

      context 'when the school is state-funded' do
        let(:school) { FactoryBot.create(:school, :state_funded) }

        it 'returns :state_school_appropriate_body' do
          expect(subject.previous_step).to eq(:state_school_appropriate_body)
        end
      end
    end
  end

  context '#save!' do
    subject { wizard.current_step }

    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :training_programme, step_params:) }

    context 'when the step is not valid' do
      let(:step_params) { ActionController::Parameters.new("training_programme" => {}) }

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :training_programme)
      end
    end

    context 'when the step is valid' do
      let(:step_params) do
        ActionController::Parameters.new(
          "training_programme" => {
            "training_programme" => 'provider_led',
          }
        )
      end

      it 'updates the wizard ect programme type' do
        expect { subject.save! }
          .to change(subject.ect, :training_programme).from(nil).to('provider_led')
      end
    end
  end
end
