RSpec.describe "Appropriate Body bulk actions confirmation", type: :request do
  include AuthHelper
  include ActiveJob::TestHelper

  let(:appropriate_body) { create(:appropriate_body) }
  let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }
  let(:batch) do
    create(:pending_induction_submission_batch, :action,
           appropriate_body:,
           data:,
           filename: 'test-file.csv')
  end

  include_context 'fake trs api client'
  include_context '3 valid actions'

  describe 'PATCH /appropriate-body/bulk/actions/:batch_id' do
    it "enqueues a job" do
      expect {
        put ab_batch_action_path(batch)
      }.to have_enqueued_job(ProcessBatchActionJob).with(batch, user.email, user.name)
    end

    it "records an upload completed event" do
      allow(Events::Record).to receive(:record_bulk_upload_completed_event!).and_call_original

      put ab_batch_action_path(batch)

      expect(Events::Record).to have_received(:record_bulk_upload_completed_event!).with(
        batch:,
        author: an_instance_of(Sessions::Users::AppropriateBodyPersona)
      )

      perform_enqueued_jobs

      expect(Event.last.event_type).to eq("bulk_upload_completed")
    end

    it "redirects" do
      put ab_batch_action_path(batch)

      expect(response).to redirect_to(ab_batch_action_path(batch))
      follow_redirect!
      expect(response.body).to include("We're processing your CSV file, it could take up to 5 minutes.")

      perform_enqueued_jobs
      get ab_batch_action_path(batch)
      # NB: these will have failed because we have not factoried the ECTs and their inductions
      expect(response.body).to include("Your CSV named 'test-file.csv' has 3 ECTs with errors")
    end
  end
end
