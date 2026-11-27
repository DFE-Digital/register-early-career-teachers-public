RSpec.describe Schools::Mentors::ChangeNameWizard::Steps::ConfirmationStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:school) { FactoryBot.create(:school) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:) }
  let(:wizard) do
    Schools::Mentors::ChangeNameWizard::Wizard.new(
      current_step: :confirmation,
      state_store:
    )
  end
  let(:state_store) do
    Schools::Mentors::ChangeNameWizard::StateStore.new(
      repository: DfE::Wizard::Repository::InMemory.new,
      mentor_at_school_period:
    )
  end

  before { state_store.write(name: "Terry Pratchett") }

  describe "#new_name" do
    it "returns the changed name" do
      expect(current_step.new_name).to eq("Terry Pratchett")
    end
  end
end
