RSpec.describe Schools::Mentors::ChangeNameWizard::Wizard do
  subject(:wizard) do
    described_class.new(
      state_store:,
      current_step: :edit,
      current_step_params: { edit: { name: } }
    )
  end

  let(:school) { FactoryBot.create(:school) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Terry", trs_last_name: "Smith") }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, teacher:) }
  let(:name) { "Terry Pratchett" }
  let(:state_store) do
    Schools::Mentors::ChangeNameWizard::StateStore.new(
      repository: DfE::Wizard::Repository::InMemory.new,
      mentor_at_school_period:
    )
  end

  before do
    allow(Current).to receive(:user).and_return(author)
  end

  it { is_expected.to have_root_step(:edit) }

  it "defines a route for every step" do
    expect(described_class.routes).to match_array(wizard.step_definitions.keys)
  end

  it "resolves nested mentor step paths" do
    expect(wizard).to resolve_step(:check_answers).to(
      "/school/mentors/#{mentor_at_school_period.id}/change-name/check-answers"
    )
  end

  it "resolves the mentor details path" do
    expect(wizard.details_path).to eq("/school/mentors/#{mentor_at_school_period.id}")
  end

  describe "navigation" do
    before do
      state_store.write(name:)
    end

    context "when only part of the name changes" do
      let(:name) { "Terry Pratchett" }

      it "skips the confirmation step" do
        expect(wizard.next_step).to eq(:check_answers)
      end
    end

    context "when both first and last names change" do
      let(:name) { "Nanny Ogg" }

      it "routes through name-change confirmation before check answers" do
        expect(wizard.next_step).to eq(:confirm_name_change)

        confirmation_wizard = described_class.new(
          state_store:,
          current_step: :confirm_name_change
        )

        expect(confirmation_wizard.next_step).to eq(:check_answers)
      end
    end

    it { is_expected.to have_next_step(:check_answers).from(:confirm_name_change) }
    it { is_expected.to have_next_step(:confirmation).from(:check_answers) }
  end

  describe "operations" do
    it "updates the mentor on the check answers step" do
      expect(wizard).to have_step_operations(
        check_answers: [Schools::Mentors::ChangeNameWizard::Operations::UpdateName]
      )
    end
  end
end
