RSpec.describe Admin::DataFixesWizard::PreviewStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :preview,
      step_params: ActionController::Parameters.new(preview: params),
      author:,
      store:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:dfe_user, role: :product_team) }
  let(:params) { {} }

  describe ".permitted_params" do
    subject(:permitted_params) { described_class.permitted_params }

    it { is_expected.to be_empty }
  end

  describe "#previous_step" do
    subject(:previous_step) { current_step.previous_step }

    it { is_expected.to eq(:csv) }
  end

  describe "#next_step" do
    subject(:next_step) { current_step.next_step }

    it { is_expected.to be_nil }
  end
end
