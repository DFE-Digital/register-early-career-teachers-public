RSpec.describe Schools::Mentors::ChangeNameWizard::EditStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period) }
  let(:wizard) do
    FactoryBot.build(:change_mentor_name_wizard,
                     current_step: :edit,
                     mentor_at_school_period:,
                     step_params: ActionController::Parameters.new("edit" => params))
  end

  let(:params) do
    { "name" => 'Terry Pratchett' }
  end

  describe 'validations' do
    context 'when name has not changed' do
      before do
        mentor_at_school_period.teacher.update(corrected_name: 'Terry Pratchett')
      end

      it 'is not valid' do
        expect(current_step).not_to be_valid
        expect(current_step.errors[:name]).to include('The name must be different from the current name')
      end
    end

    context 'when name is blank' do
      let(:params) do
        { "name" => '' }
      end

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

  describe '#save!' do
    context 'when the step is not valid' do
      let(:params) do
        { "name" => '' }
      end

      it 'does not cache the new name' do
        expect { current_step.save! }.not_to change(wizard.store, :name)
      end
    end

    context 'when the step is valid' do
      it 'caches the new name' do
        expect { current_step.save! }.to change(wizard.store, :name).from(nil).to('Terry Pratchett')
      end
    end
  end
end
