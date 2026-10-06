RSpec.describe Admin::DataFixesWizard::Steps::ConfirmationStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :confirmation,
      current_step_params: ActionController::Parameters.new(confirmation: {}),
      state_store:
    )
  end
  let(:state_store) { Admin::DataFixesWizard::StateStore.new(repository:) }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  it { is_expected.to delegate_method(:state_store).to(:wizard) }
  it { is_expected.to delegate_method(:confirmed_changes).to(:state_store) }
end
