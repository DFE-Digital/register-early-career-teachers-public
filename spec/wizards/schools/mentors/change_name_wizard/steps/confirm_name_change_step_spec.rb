RSpec.describe Schools::Mentors::ChangeNameWizard::Steps::ConfirmNameChangeStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:school) { FactoryBot.create(:school) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:) }
  let(:wizard) do
    Schools::Mentors::ChangeNameWizard::Wizard.new(
      current_step: :confirm_name_change,
      state_store:
    )
  end
  let(:state_store) do
    Schools::Mentors::ChangeNameWizard::StateStore.new(
      repository: DfE::Wizard::Repository::InMemory.new,
      mentor_at_school_period:
    )
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
