describe Schools::Mentors::ChangeEmailAddressWizard::Steps::ConfirmationStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::Mentors::ChangeEmailAddressWizard::Wizard.new(
      current_step: :confirmation,
      current_step_params: { confirmation: params },
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
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:) }
  let(:params) { {} }

  before do
    allow(wizard).to receive(:author).and_return(author)
  end

  describe "#new_email" do
    it "returns the mentor's email" do
      expect(current_step.new_email).to eq(mentor_at_school_period.email)
    end
  end
end
