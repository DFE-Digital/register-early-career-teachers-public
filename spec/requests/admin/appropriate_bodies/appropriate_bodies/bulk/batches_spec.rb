describe "Admin::AppropriateBodies::Bulk::BatchesController", type: :request do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: 'Busy Body') }

  describe "GET /admin/organisations/appropriate-bodies/:appropriate_body_id/bulk/batches" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get admin_appropriate_body_bulk_batches_path(appropriate_body)

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as a non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get admin_appropriate_body_bulk_batches_path(appropriate_body)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as a DfE user" do
      include_context "sign in as DfE user"

      before do
        FactoryBot.create(:pending_induction_submission_batch, :processed, :action, appropriate_body:)
        FactoryBot.create(:pending_induction_submission_batch, :completed, :action, appropriate_body:)

        # Batches from different appropriate bodies
        FactoryBot.create(:pending_induction_submission_batch, :failed, :action)
        FactoryBot.create(:pending_induction_submission_batch, :completing, :action)
        FactoryBot.create(:pending_induction_submission_batch, :pending, :action)
      end

      it "lists only the appropriate body's bulk uploads" do
        get admin_appropriate_body_bulk_batches_path(appropriate_body)
        expect(response.body).to include("CSV Uploads for Busy Body")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Processed")
        expect(response.body).to include("Completed")

        expect(response.body).not_to include("Pending")
        expect(response.body).not_to include("Completing")
        expect(response.body).not_to include("Failed")
      end
    end
  end

  describe "GET /admin/organisations/appropriate-bodies/:appropriate_body_id/bulk/batches/:id" do
    let!(:batch) do
      FactoryBot.create(:pending_induction_submission_batch,
                        :action,
                        :completed,
                        file_name: "busy body actions.csv",
                        appropriate_body:)
    end

    context "when not authenticated" do
      it "redirects to the sign in page" do
        get admin_appropriate_body_bulk_batch_path(appropriate_body, batch)

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "is unauthorised" do
        get admin_appropriate_body_bulk_batch_path(appropriate_body, batch)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as a DfE user" do
      include_context "sign in as DfE user"

      it "renders details of the upload" do
        get admin_appropriate_body_bulk_batch_path(appropriate_body, batch)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("CSV upload by Busy Body")
        expect(response.body).to include("busy body actions.csv")
        expect(response.body).to include("Completed")
      end
    end
  end
end
