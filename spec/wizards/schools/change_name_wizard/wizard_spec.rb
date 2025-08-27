RSpec.describe Schools::ChangeNameWizard::Wizard do
  subject(:wizard) do
    FactoryBot.build(:change_name_wizard, ect_id: ect.id)
  end

  let(:ect) { FactoryBot.create(:ect_at_school_period) }

  describe '#ect' do
    it 'finds the ECT' do
      expect(wizard.ect).to eq(ect)
    end
  end

  describe '#current_step_path' do
    it { expect(wizard.current_step_path).to eq "/school/ects/#{ect.id}/change-name/edit" }
  end

  describe '#next_step_path' do
    it { expect(wizard.next_step_path).to eq "/school/ects/#{ect.id}/change-name/check-answers" }
  end

  describe '#previous_step_path' do
    subject(:wizard) do
      FactoryBot.build(:change_name_wizard, ect_id: ect.id, current_step: :confirmation)
    end

    it { expect(wizard.previous_step_path).to eq "/school/ects/#{ect.id}/change-name/check-answers" }
  end
end
