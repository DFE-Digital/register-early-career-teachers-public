describe "Admin::AppropriateBodies::Bulk::BatchesController", type: :request do
  describe "GET index" do
    let!(:appropriate_body) { FactoryBot.create(:appropriate_body) }

    context "when unauthenticated" do
      it "redirects to the sign in page" do
        get admin_appropriate_body_bulk_batches_path(appropriate_body)

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "is unauthorised" do
        get admin_appropriate_body_bulk_batches_path(appropriate_body)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as a DfE user" do
      include_context "sign in as DfE user"

      it "lists the appropriate body's bulk uploads" do
        batch = FactoryBot.create(
          :pending_induction_submission_batch,
          :processed,
          :action,
          appropriate_body:
        )
        other_appropriate_body = FactoryBot.create(:appropriate_body)
        other_batch = FactoryBot.create(
          :pending_induction_submission_batch,
          :pending,
          :action,
          appropriate_body: other_appropriate_body
        )

        get admin_appropriate_body_bulk_batches_path(appropriate_body)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(batch.id.to_s)
        expect(response.body).to include("Processed")
        expect(response.body).not_to include(other_batch.id.to_s)
        expect(response.body).not_to include("Pending")
      end
    end
  end
end
