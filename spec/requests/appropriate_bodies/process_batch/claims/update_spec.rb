RSpec.describe "Appropriate Body bulk claims confirmation", type: :request do
  include AuthHelper
  include ActiveJob::TestHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }
  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim,
                      appropriate_body:,
                      data:,
                      file_name:)
  end

  include_context 'test trs api client'

  describe 'PATCH /appropriate-body/bulk/claims/:batch_id' do
    context 'with only valid claims' do
      include_context '2 valid claims'

      it "enqueues a job" do
        expect {
          put ab_batch_claim_path(batch)
        }.to have_enqueued_job(ProcessBatchClaimJob).with(batch, user.email, user.name)
      end

      it "records an upload completed event" do
        allow(Events::Record).to receive(:record_bulk_upload_completed_event!).and_call_original

        put ab_batch_claim_path(batch)

        expect(Events::Record).to have_received(:record_bulk_upload_completed_event!).with(
          batch:,
          author: an_instance_of(Sessions::Users::AppropriateBodyPersona)
        )

        perform_enqueued_jobs

        expect(Event.last.event_type).to eq("bulk_upload_completed")
        expect(Event.last.pending_induction_submission_batch.id).to eq(batch.id)
      end

      it "redirects" do
        put ab_batch_claim_path(batch)

        expect(response).to redirect_to(ab_batch_claim_path(batch))
        follow_redirect!
        expect(response.body).to include("We're processing your CSV file, it could take up to 5 minutes.")

        perform_enqueued_jobs
        get ab_batch_claim_path(batch)

        expect(response.body).to include("Your CSV named '2 valid claims.csv' has 2 ECT records that you can claim")
      end
    end

    context 'with one valid and one invalid claim' do
      include_context '1 valid and 1 invalid claim'

      it "redirects and renders a summary of successful outcomes and errors to fix" do
        put ab_batch_claim_path(batch)

        expect(response).to redirect_to(ab_batch_claim_path(batch))
        follow_redirect!
        expect(response.body).to include("We're processing your CSV file, it could take up to 5 minutes.")

        perform_enqueued_jobs
        get ab_batch_claim_path(batch)

        expect(response.body).to include("Your CSV named '1 valid 1 invalid claim.csv' has 1 ECT record that you can claim")
        expect(response.body).to include("You have 1 ECT with errors")
      end
    end

    context 'with no valid claims' do
      let(:file_name) { 'no valid claims.csv' }

      let(:data) do
        [{ trn: '7654321', date_of_birth: '1981-06-30' }]
      end

      it "redirects and renders a summary of errors to fix" do
        put ab_batch_claim_path(batch)

        expect(response).to redirect_to(ab_batch_claim_path(batch))
        follow_redirect!
        expect(response.body).to include("We're processing your CSV file, it could take up to 5 minutes.")

        perform_enqueued_jobs
        get ab_batch_claim_path(batch)

        expect(response.body).to include("Your CSV named 'no valid claims.csv' has 1 ECT with errors")
        expect(response.body).to include("Download CSV with error messages included")
        expect(response.body).to include("You'll need to fix these errors before you try again.")
      end
    end
  end
end
