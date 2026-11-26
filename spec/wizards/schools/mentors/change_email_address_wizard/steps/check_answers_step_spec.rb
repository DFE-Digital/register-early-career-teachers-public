describe Schools::Mentors::ChangeEmailAddressWizard::Steps::CheckAnswersStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::Mentors::ChangeEmailAddressWizard::Wizard.new(
      current_step: :check_answers,
      current_step_params: { check_answers: params },
      state_store:
    )
  end
  let(:state_store) do
    Schools::Mentors::ChangeEmailAddressWizard::StateStore.new(
      repository: DfE::Wizard::Repository::InMemory.new,
      mentor_at_school_period:
    )
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:mentor_at_school_period) do
    FactoryBot.create(:mentor_at_school_period, school:, email: "old@example.com")
  end
  let(:params) { {} }

  before do
    state_store.write(email: "new@example.com")
    allow(wizard).to receive(:author).and_return(author)
  end

  describe "#current_email" do
    it "returns the current email" do
      expect(current_step.current_email).to eq("old@example.com")
    end
  end

  describe "#new_email" do
    it "returns the new email" do
      expect(current_step.new_email).to eq("new@example.com")
    end
  end
end
