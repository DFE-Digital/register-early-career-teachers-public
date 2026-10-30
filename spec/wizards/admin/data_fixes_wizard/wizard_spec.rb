RSpec.describe Admin::DataFixesWizard::Wizard do
  include DfE::Wizard::Test::RSpecMatchers

  subject(:wizard) { Admin::DataFixesWizard::Wizard.new(state_store:) }

  let(:state_store) { Admin::DataFixesWizard::StateStore.new(repository:) }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  describe ".routes" do
    subject(:routes) { described_class.routes }

    it { is_expected.to eq(%i[csv preview verify confirmation]) }
  end

  it { is_expected.to delegate_method(:clear).to(:state_store) }

  describe "#author" do
    subject(:author) { wizard.author }

    let(:current_user) { FactoryBot.create(:dfe_user, role: "product_team") }

    before { allow(Current).to receive(:user).and_return(current_user) }

    it { is_expected.to eq(current_user) }
  end

  describe "#error_presenter" do
    subject(:error_presenter) { wizard.error_presenter }

    it { is_expected.to eq(Admin::DataFixesWizard::Wizard::ErrorSummaryPresenter) }
  end

  describe "#steps_processor" do
    it "defines the root path" do
      expect(wizard).to have_root_step(:csv)
    end

    it "defines the flow" do
      expect(wizard)
        .to branch_from(:csv).to(:preview)
        .and branch_from(:preview).to(:verify)
        .and branch_from(:verify).to(:confirmation)
    end
  end

  describe "#steps_operator" do
    it "defines the step operations" do
      expect(wizard).to have_step_operations({
        csv: [
          DfE::Wizard::Operations::Validate,
          Admin::DataFixesWizard::Operations::ParseCSV,
          DfE::Wizard::Operations::Persist
        ],
        preview: [
          Admin::DataFixesWizard::Operations::ProcessChanges,
          DfE::Wizard::Operations::Persist
        ],
        verify: [
          DfE::Wizard::Operations::Validate,
          Admin::DataFixesWizard::Operations::ConfirmChanges,
          DfE::Wizard::Operations::Persist
        ]
      })
    end
  end
end
