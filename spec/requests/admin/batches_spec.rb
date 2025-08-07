RSpec.describe "Admin::BatchesController", type: :request do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: 'Busy Body') }

  before do
    FactoryBot.create(:pending_induction_submission_batch, :action, appropriate_body:)
  end

  describe "GET /admin/batches" do
    context "when signed in as admin" do
      include_context 'sign in as DfE user'

      it "renders successfully" do
        get admin_batches_path
        expect(response).to be_successful
        expect(response.body).to include("Bulk uploads")
      end

      it "shows batches in the table" do
        get admin_batches_path
        expect(response.body).to include('Busy Body')
        expect(response.body).to include('Action')
      end
    end

    context "when signed in as a non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get admin_batches_path
        expect(response.status).to eq(401)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get admin_batches_path
        expect(response).to be_redirection
      end
    end
  end
end
