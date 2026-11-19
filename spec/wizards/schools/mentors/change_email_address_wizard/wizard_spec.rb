RSpec.describe Schools::Mentors::ChangeEmailAddressWizard::Wizard do
  subject(:wizard) { described_class.new(state_store:, current_step: :edit) }

  let(:school) { FactoryBot.create(:school) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:) }
  let(:state_store) do
    Schools::Mentors::ChangeEmailAddressWizard::StateStore.new(
      repository: DfE::Wizard::Repository::InMemory.new,
      author:,
      mentor_at_school_period:
    )
  end

  it { is_expected.to have_root_step(:edit) }

  it "defines a route for every step" do
    expect(described_class.routes).to match_array(wizard.step_definitions.keys)
  end

  it "resolves nested mentor step paths" do
    expect(wizard).to resolve_step(:check_answers).to(
      "/school/mentors/#{mentor_at_school_period.id}/change-email-address/check-answers"
    )
  end

  describe "navigation" do
    it { is_expected.to have_next_step(:check_answers).from(:edit) }
    it { is_expected.to have_next_step(:confirmation).from(:check_answers) }
  end

  describe "operations" do
    it "updates the mentor on the check answers step" do
      expect(wizard).to have_step_operations(
        check_answers: [Schools::Mentors::ChangeEmailAddressWizard::Operations::UpdateEmail]
      )
    end
  end
end
