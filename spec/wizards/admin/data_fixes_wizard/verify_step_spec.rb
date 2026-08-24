RSpec.describe Admin::DataFixesWizard::VerifyStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :verify,
      step_params: ActionController::Parameters.new(verify: params),
      author:,
      store:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:dfe_user, role: :product_team) }
  let(:params) { {} }

  it { is_expected.to delegate_method(:processed_changes).to(:store) }

  describe ".permitted_params" do
    subject(:permitted_params) { described_class.permitted_params }

    it { is_expected.to be_empty }
  end

  describe "#previous_step" do
    subject(:previous_step) { current_step.previous_step }

    it { is_expected.to eq(:preview) }
  end

  describe "#next_step" do
    subject(:next_step) { current_step.next_step }

    it { is_expected.to be_nil }
  end
end
