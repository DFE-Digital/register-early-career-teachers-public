RSpec.describe Schools::Mentors::ChangeNameWizard::Steps::EditStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:school) { FactoryBot.create(:school) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Terry", trs_last_name: "Smith") }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, teacher:) }
  let(:wizard) do
    Schools::Mentors::ChangeNameWizard::Wizard.new(
      current_step: :edit,
      current_step_params: { edit: params },
      state_store:
    )
  end
  let(:state_store) do
    Schools::Mentors::ChangeNameWizard::StateStore.new(
      repository: DfE::Wizard::Repository::InMemory.new,
      mentor_at_school_period:
    )
  end
  let(:params) { { name: "Terry Pratchett" } }

  describe ".permitted_params" do
    it "returns the permitted parameters" do
      expect(described_class.permitted_params).to contain_exactly(:name)
    end
  end

  describe "validations" do
    context "when name has not changed" do
      before do
        teacher.update!(corrected_name: "Terry Pratchett")
      end

      it "is not valid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:name)).to contain_exactly(
          "The name must be different from the current name"
        )
      end
    end

    context "when name is blank" do
      let(:params) { { name: "" } }

      it "is not valid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:name)).to include("Enter the correct full name")
      end
    end

    context "when name is valid" do
      it "is valid" do
        expect(current_step).to be_valid
        expect(current_step.errors).to be_empty
      end
    end
  end

  describe "saving" do
    it "persists the submitted name" do
      expect(wizard.save_current_step).to be(true)
      expect(state_store[:name]).to eq("Terry Pratchett")
    end
  end
end
