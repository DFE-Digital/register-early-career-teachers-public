RSpec.describe "Admin Bulk Batches", type: :request do
  include AuthHelper

  let(:admin_user) { sign_in_as(:dfe_staff_user) }
  let(:appropriate_body) { create(:appropriate_body) }
  let!(:batch) { create(:pending_induction_submission_batch, :action, appropriate_body:) }

  describe "GET /admin/bulk/batches" do
    context "when signed in as admin" do
      include_context 'sign in as DfE user'

      it "renders successfully" do
        get admin_bulk_batches_path
        expect(response).to be_successful
        expect(response.body).to include("Bulk upload batches")
      end

      it "shows batches in the table" do
        get admin_bulk_batches_path
        expect(response.body).to include(batch.appropriate_body.name)
        expect(response.body).to include('Action')
      end
    end

    context "when signed in as a non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get admin_bulk_batches_path
        expect(response.status).to eq(401)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get admin_bulk_batches_path
        expect(response).to be_redirection
      end
    end
  end

  describe "GET /admin/bulk/batches/:id" do
    context "when signed in as admin" do
      include_context 'sign in as DfE user'

      it "renders successfully" do
        get admin_bulk_batch_path(batch)
        expect(response).to be_successful
        expect(response.body).to include("Checking bulk")
      end

      it "shows batch details" do
        get admin_bulk_batch_path(batch)
        expect(response.body).to include(batch.appropriate_body.name)
        expect(response.body).to include("Batch ID")
      end
    end

    context "when signed in as a non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get admin_bulk_batch_path(batch)
        expect(response.status).to eq(401)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get admin_bulk_batch_path(batch)
        expect(response).to be_redirection
      end
    end
  end
end
