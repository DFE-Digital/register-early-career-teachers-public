RSpec.describe Schools::RegisterECTWizard::StateSchoolAppropriateBodyStep, type: :model do
  let(:school) { FactoryBot.create(:school, :state_funded) }
  let(:store) { FactoryBot.build(:session_repository, appropriate_body_id: '123') }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :state_school_appropriate_body, store:, school:) }

  describe '#initialize' do
    let(:appropriate_body_id) { 'provided_ab_name' }
    subject { described_class.new(wizard:, **params) }

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
    subject { described_class.new(appropriate_body_id:) }

    context 'when the appropriate_body_id is not present' do
      let(:appropriate_body_id) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body_id]).to include("Enter the name of the appropriate body which will be supporting the ECT's induction")
      end
    end

    context 'when the appropriate_body_id is present' do
      let(:appropriate_body_id) { '1' }

      it { expect(subject).to be_valid }
    end
  end

  describe 'steps' do
    subject { wizard.current_step }

    describe '#next_step' do
      it 'returns the next step' do
        expect(subject.next_step).to eq(:programme_type)
      end
    end

    describe '#previous_step' do
      subject { wizard.current_step }

      context 'when the school has no programme choices' do
        it 'returns the previous step' do
          expect(subject.previous_step).to eq(:working_pattern)
        end
      end

      context 'when the school has programme choices' do
        let(:school) { FactoryBot.create(:school, :state_funded, :teaching_school_hub_chosen, :provider_led_chosen) }

        it 'returns the previous step' do
          expect(subject.previous_step).to eq(:use_previous_ect_choices)
        end
      end
    end
  end

  describe '#save!' do
    let(:step_params) do
      ActionController::Parameters.new(
        "state_school_appropriate_body" => {
          "appropriate_body_id" => '1',
        }
      )
    end

    let(:wizard) do
      FactoryBot.build(:register_ect_wizard, current_step: :state_school_appropriate_body, step_params:)
    end

    subject { wizard.current_step }

    context 'when the step is not valid' do
      before do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :appropriate_body_id)
      end
    end

    context 'when the step is valid' do
      before do
        allow(subject).to receive(:valid?).and_return(true)
      end

      it 'updates the wizard ect appropriate_body_id' do
        expect { subject.save! }
          .to change(subject.ect, :appropriate_body_id)
                .from(nil).to('1')
                .and change(subject.ect, :appropriate_body_type)
                       .from(nil).to('teaching_school_hub')
      end
    end
  end
end
