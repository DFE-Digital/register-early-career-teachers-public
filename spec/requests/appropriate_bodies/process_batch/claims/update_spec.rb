RSpec.describe "Appropriate Body bulk claims confirmation", type: :request do
  include AuthHelper
  include ActiveJob::TestHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }
  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim,
                      appropriate_body:,
                      data:,
                      file_name: 'test-file.csv')
  end

  include_context 'fake trs api client'
  include_context '2 valid claims'

  describe 'PATCH /appropriate-body/bulk/claims/:batch_id' do
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
      # NB: these will have failed because we have not factoried the ECTs and their inductions
      expect(response.body).to include("Your CSV named 'test-file.csv' has 2 ECTs with errors")
    end
  end
end
