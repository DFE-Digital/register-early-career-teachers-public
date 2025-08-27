RSpec.describe Schools::ChangeNameWizard::EditStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    FactoryBot.build(:change_name_wizard,
                     current_step: :edit,
                     step_params:)
  end

  let(:step_params) do
    ActionController::Parameters.new("edit" => {})
  end

  describe 'validations' do
    context 'when name is not present' do
      it 'is not valid' do
        expect(current_step).not_to be_valid
        expect(current_step.errors[:name]).to include('Enter the correct full name')
      end
    end
  end

  describe '#next_step' do
    it { expect(current_step.next_step).to eq(:check_answers) }
  end

  describe '#previous_step' do
    it { expect { current_step.previous_step }.to raise_error(NotImplementedError) }
  end

  context '#save!' do
    context 'when the step is not valid' do
      it 'does not cache the new name' do
        expect { current_step.save! }.not_to change(wizard.store, :new_name)
      end
    end

    context 'when the step is valid' do
      let(:step_params) do
        ActionController::Parameters.new(
          "edit" => {
            "name" => 'New Name',
          }
        )
      end

      it 'caches the new name' do
        expect { current_step.save! }.to change(wizard.store, :new_name).from(nil).to('New Name')
      end
    end
  end
end
