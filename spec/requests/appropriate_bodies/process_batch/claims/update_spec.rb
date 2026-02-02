RSpec.describe "Appropriate Body bulk claims confirmation", type: :request do
  include ActiveJob::TestHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }
  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim, :processed,
                      appropriate_body:,
                      data:,
                      file_name:)
  end

  include_context "test TRS API returns a teacher"

  describe "PATCH /appropriate-body/bulk/claims/:batch_id" do
    context "with only valid claims" do
      include_context "2 valid claims"

      it "enqueues a job" do
        expect {
          put ab_batch_claim_path(batch)
        }.to have_enqueued_job(AppropriateBodies::ProcessBatch::ClaimJob).with(batch, user.email, user.name).exactly(1).times
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
        expect(response.body).to include("ECTs successfully claimed")
      end

      it "prevents duplicates" do
        expect {
          put ab_batch_claim_path(batch)
        }.to have_enqueued_job(AppropriateBodies::ProcessBatch::ClaimJob).with(batch, user.email, user.name)

        expect {
          put ab_batch_claim_path(batch)
        }.not_to have_enqueued_job(AppropriateBodies::ProcessBatch::ClaimJob)
      end
    end
  end
end
