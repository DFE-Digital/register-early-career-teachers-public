RSpec.describe Schools::RegisterECTWizard::ProgrammeTypeStep, type: :model do
  describe '#initialize' do
    let(:school) { FactoryBot.build(:school) }
    let(:store) { FactoryBot.build(:session_repository, programme_type: 'prepopulated_programme_type') }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :programme_type, school:, store:) }

    let(:programme_type) { 'provided_programme_type' }
    subject { described_class.new(wizard:, **params) }

    context 'when the programme_type is provided' do
      let(:params) { { programme_type: } }

      it 'populate the instance from it' do
        expect(subject.programme_type).to eq(programme_type)
      end
    end

    context 'when no programme_type is provided' do
      let(:params) { {} }

      it 'populate it from the wizard store' do
        expect(subject.programme_type).to eq('prepopulated_programme_type')
      end
    end
  end

  describe 'validations' do
    subject { described_class.new(programme_type:) }

    context 'when the programme_type is not present' do
      let(:programme_type) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:programme_type]).to include("Select either 'Provider-led' or 'School-led' training")
      end
    end

    context 'when the programme_type is has an unknown value' do
      let(:programme_type) { 'unknown_programme_type' }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:programme_type]).to include("'unknown_programme_type' is not a valid programme type")
      end
    end

    context 'when the programme_type is present and a known value' do
      let(:programme_type) { 'provider_led' }

      it { expect(subject).to be_valid }
    end
  end

  describe 'steps' do
    let(:school) { FactoryBot.build(:school) }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :programme_type, school:) }

    subject { wizard.current_step }

    describe '#next_step' do
      context 'when programme_type is provider_led' do
        before do
          allow(wizard.ect).to receive(:provider_led?).and_return(true)
        end

        it 'returns the next step' do
          expect(subject.next_step).to eq(:lead_provider)
        end
      end

      context 'when programme_type is school_led' do
        it 'returns the next step' do
          expect(subject.next_step).to eq(:check_answers)
        end
      end
    end

    describe '#previous_step' do
      context 'when the school is independent' do
        before do
          allow(school).to receive(:independent?).and_return(true)
        end

        it 'returns :independent_school_appropriate_body' do
          expect(subject.previous_step).to eq(:independent_school_appropriate_body)
        end
      end

      context 'when the school is state-funded' do
        before do
          allow(school).to receive(:independent?).and_return(false)
        end

        it 'returns :state_school_appropriate_body' do
          expect(subject.previous_step).to eq(:state_school_appropriate_body)
        end
      end
    end
  end

  context '#save!' do
    let(:step_params) do
      ActionController::Parameters.new(
        "programme_type" => {
          "programme_type" => 'provider_led',
        }
      )
    end
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :programme_type, step_params:) }

    subject { wizard.current_step }

    context 'when the step is not valid' do
      before do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :programme_type)
      end
    end

    context 'when the step is valid' do
      before do
        allow(subject).to receive(:valid?).and_return(true)
      end

      it 'updates the wizard ect programme type' do
        expect { subject.save! }
          .to change(subject.ect, :programme_type).from(nil).to('provider_led')
      end
    end
  end
end
