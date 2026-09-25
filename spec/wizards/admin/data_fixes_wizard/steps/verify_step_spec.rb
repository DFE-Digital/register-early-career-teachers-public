RSpec.describe Admin::DataFixesWizard::Steps::VerifyStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :verify,
      current_step_params: ActionController::Parameters.new(verify: params),
      state_store:
    )
  end
  let(:state_store) { Admin::DataFixesWizard::StateStore.new(repository:) }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  let(:params) { { note:, zendesk_ticket_id: } }
  let(:note) { "This is test note" }
  let(:zendesk_ticket_id) { "123456" }
  let(:current_user) { FactoryBot.create(:dfe_user, role: "product_team") }

  before { allow(wizard).to receive(:author).and_return(current_user) }

  it { is_expected.to delegate_method(:author).to(:wizard) }
  it { is_expected.to delegate_method(:state_store).to(:wizard) }
  it { is_expected.to delegate_method(:processed_changes).to(:state_store) }

  describe ".permitted_params" do
    subject(:permitted_params) { described_class.permitted_params }

    it { is_expected.to contain_exactly(:zendesk_ticket_id, :note) }
  end

  describe "validations" do
    context "when author is missing" do
      let(:current_user) { nil }

      it { is_expected.to have_error(:author, "can't be blank") }
    end

    context "when note and zendesk_ticket_id are both missing" do
      let(:note) { "" }
      let(:zendesk_ticket_id) { "" }

      it { is_expected.to have_error(:base, "Add a note or enter the Zendesk ticket number") }
    end

    context "when zendesk_ticket_id is not 6 digits" do
      let(:zendesk_ticket_id) { "1234" }

      it { is_expected.to have_error(:zendesk_ticket_id, "Ticket number must be 6 digits") }
    end

    context "when author and note are present" do
      let(:note) { "This is a note about the changes being made." }
      let(:zendesk_ticket_id) { "" }

      it { is_expected.to be_valid }
    end

    context "when author and zendesk_ticket_id are present" do
      let(:note) { "" }
      let(:zendesk_ticket_id) { "123456" }

      it { is_expected.to be_valid }
    end
  end
end
