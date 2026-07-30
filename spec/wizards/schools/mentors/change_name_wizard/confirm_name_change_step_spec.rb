RSpec.describe Schools::Mentors::ChangeNameWizard::ConfirmNameChangeStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period) }
  let(:store) { FactoryBot.build(:session_repository, name: "Nanny Ogg") }
  let(:wizard) do
    FactoryBot.build(:change_mentor_name_wizard,
                     current_step: :confirm_name_change,
                     store:,
                     mentor_at_school_period:)
  end

  describe "#previous_step" do
    it { expect(current_step.previous_step).to eq(:edit) }
  end

  describe "#next_step" do
    it { expect(current_step.next_step).to eq(:check_answers) }
  end

  describe "#save!" do
    it "does not change the teacher's name" do
      expect { current_step.save! }.not_to change(mentor_at_school_period.teacher.reload, :corrected_name)
    end

    it "returns true so the wizard can continue" do
      expect(current_step.save!).to be(true)
    end
  end
end
