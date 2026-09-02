RSpec.describe Admin::DataFixesWizard::ConfirmationStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :confirmation,
      step_params: ActionController::Parameters.new(confirmation: params),
      author:,
      store:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:dfe_user, role: :product_team) }
  let(:params) { {} }

  it { is_expected.to delegate_method(:confirmed_changes).to(:store) }

  describe ".permitted_params" do
    subject(:permitted_params) { described_class.permitted_params }

    it { is_expected.to be_empty }
  end
end
