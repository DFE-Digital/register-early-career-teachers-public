RSpec.describe Schools::Mentors::ChangeNameWizard::Wizard do
  subject(:wizard) do
    FactoryBot.build(:change_mentor_name_wizard, mentor_at_school_period:)
  end

  let(:teacher) do
    FactoryBot.create(:teacher, trs_first_name: "Terry", trs_last_name: "Pratchett")
  end

  let(:mentor_at_school_period) do
    FactoryBot.create(:mentor_at_school_period, teacher:)
  end

  describe "#teacher_full_name" do
    it "finds the mentor" do
      expect(wizard.teacher_full_name).to eq("Terry Pratchett")
    end
  end

  describe "#current_step_path" do
    it { expect(wizard.current_step_path).to eq "/school/mentors/#{mentor_at_school_period.id}/change-name/edit" }
  end
end
