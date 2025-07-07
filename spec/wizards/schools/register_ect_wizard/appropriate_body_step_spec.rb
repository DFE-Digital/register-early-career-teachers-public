RSpec.describe Schools::RegisterECTWizard::AppropriateBodyStep, type: :model do
  let(:school) { create(:school, :state_funded) }
  let(:store) { build(:session_repository, appropriate_body_id: '123') }
  let(:wizard) { build(:register_ect_wizard, current_step: :state_school_appropriate_body, store:, school:) }

  describe '#initialize' do
    subject { described_class.new(wizard:, **params) }

    let(:appropriate_body_id) { 'provided_ab_name' }

    context 'when the appropriate_body_id is provided' do
      let(:params) { { appropriate_body_id: } }

      it 'populate the instance from it' do
        expect(subject.appropriate_body_id).to eq(appropriate_body_id)
      end
    end

    context 'when no appropriate_body_id is provided' do
      let(:params) { {} }

      it 'populate it from the wizard store' do
        expect(subject.appropriate_body_id).to eq('123')
      end
    end
  end

  describe 'validations' do
    subject { described_class.new(wizard:, appropriate_body_id:) }

    context 'when appropriate_body_id is blank' do
      let(:appropriate_body_id) { nil }

      it 'adds an error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body]).to include("Select the appropriate body which will be supporting the ECT's induction")
      end
    end

    context 'when the appropriate_body is not registered' do
      let(:appropriate_body_id) { '999999999' }

      it 'add an error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body]).to include("Select the appropriate body which will be supporting the ECT's induction")
      end
    end

    context 'when the appropriate_body is a local authority' do
      let(:appropriate_body_id) { create(:appropriate_body, :local_authority) }

      it 'adds an error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body]).to include("Select a valid appropriate body which will be supporting the ECT's induction")
      end
    end
  end

  describe 'steps' do
    subject { wizard.current_step }

    let(:wizard) do
      build(:register_ect_wizard, current_step: :state_school_appropriate_body, store:, school:)
    end

    describe '#next_step' do
      it 'returns the next step' do
        expect(subject.next_step).to eq(:training_programme)
      end
    end

    describe '#previous_step' do
      context 'when the school has no last programme choices' do
        it 'returns the previous step' do
          expect(subject.previous_step).to eq(:working_pattern)
        end
      end

      context 'when the school has last programme choices' do
        let(:school) { create(:school, :independent, :national_ab_last_chosen, :school_led_last_chosen) }

        it 'returns the previous step' do
          expect(subject.previous_step).to eq(:use_previous_ect_choices)
        end
      end
    end
  end

  describe '#save!' do
    subject { wizard.current_step }

    let(:step_params) do
      ActionController::Parameters.new(
        "state_school_appropriate_body" => {
          "appropriate_body_id" => '1',
        }
      )
    end

    let(:wizard) do
      build(:register_ect_wizard, current_step: :state_school_appropriate_body, step_params:)
    end

    context 'when the step is not valid' do
      before do
        allow(wizard.current_step).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :appropriate_body_id)
      end
    end

    context 'when the step is valid' do
      before do
        allow(wizard.current_step).to receive(:valid?).and_return(true)
      end

      it 'updates the wizard ect appropriate_body_id' do
        expect { subject.save! }.to change(subject.ect, :appropriate_body_id).from(nil).to('1')
      end
    end
  end
end
