RSpec.describe Schools::ChangeECTNameWizard::Wizard do
  subject(:wizard) do
    FactoryBot.build(:change_ect_name_wizard, ect_id: ect_at_school_period.id)
  end

  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }

  describe '#ect_at_school_period' do
    it 'finds the ECT' do
      expect(wizard.ect_at_school_period).to eq(ect_at_school_period)
    end
  end

  describe '#current_step_path' do
    it { expect(wizard.current_step_path).to eq "/school/ects/#{ect_at_school_period.id}/change-name/edit" }
  end

  describe '#next_step_path' do
    it { expect(wizard.next_step_path).to eq "/school/ects/#{ect_at_school_period.id}/change-name/check-answers" }
  end

  describe '#previous_step_path' do
    subject(:wizard) do
      FactoryBot.build(:change_ect_name_wizard, ect_id: ect_at_school_period.id, current_step: :check_answers)
    end

    it { expect(wizard.previous_step_path).to eq "/school/ects/#{ect_at_school_period.id}/change-name/edit" }
  end
end
