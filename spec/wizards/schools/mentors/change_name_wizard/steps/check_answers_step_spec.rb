RSpec.describe Schools::Mentors::ChangeNameWizard::Steps::CheckAnswersStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:school) { FactoryBot.create(:school) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Terry", trs_last_name: "Smith") }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, teacher:) }
  let(:wizard) do
    Schools::Mentors::ChangeNameWizard::Wizard.new(
      current_step: :check_answers,
      state_store:
    )
  end
  let(:state_store) do
    Schools::Mentors::ChangeNameWizard::StateStore.new(
      repository: DfE::Wizard::Repository::InMemory.new,
      mentor_at_school_period:
    )
  end

  before do
    state_store.write(name: "Terry Pratchett")
  end

  describe "#current_name" do
    it "returns the mentor's current name" do
      expect(current_step.current_name).to eq("Terry Smith")
    end
  end

  describe "#new_name" do
    it "returns the new name" do
      expect(current_step.new_name).to eq("Terry Pratchett")
    end
  end
end
