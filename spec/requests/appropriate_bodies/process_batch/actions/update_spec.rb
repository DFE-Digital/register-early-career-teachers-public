RSpec.describe "Appropriate Body bulk actions confirmation", type: :request do
  include AuthHelper
  include ActiveJob::TestHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }
  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :action,
                      appropriate_body:,
                      data:,
                      file_name:)
  end

  include_context 'test trs api client'

  describe 'PATCH /appropriate-body/bulk/actions/:batch_id' do
    context 'with only valid actions' do
      include_context '3 valid actions'

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
        expect(Event.last.pending_induction_submission_batch.id).to eq(batch.id)
      end

      it "redirects and renders a summary of successful outcomes" do
        put ab_batch_action_path(batch)

        expect(response).to redirect_to(ab_batch_action_path(batch))
        follow_redirect!
        expect(response.body).to include("We're processing your CSV file, it could take up to 5 minutes.")

        perform_enqueued_jobs
        get ab_batch_action_path(batch)

        expect(response.body).to include("Your CSV named '3 valid actions.csv' has 3 ECT records including:")
        expect(response.body).to include("1 ECT with a passed induction")
        expect(response.body).to include("1 ECT with a failed induction")
        expect(response.body).to include("1 ECT with a released outcome")
      end
    end

    context 'with 1 valid and 2 invalid actions' do
      include_context '1 valid and 2 invalid actions'

      it "redirects and renders a summary of successful outcomes and errors to fix" do
        put ab_batch_action_path(batch)

        expect(response).to redirect_to(ab_batch_action_path(batch))
        follow_redirect!
        expect(response.body).to include("We're processing your CSV file, it could take up to 5 minutes.")

        perform_enqueued_jobs
        get ab_batch_action_path(batch)

        expect(response.body).to include("Your CSV named '1 valid 2 invalid actions.csv' has 1 ECT record including:")
        expect(response.body).to include("1 ECT with a passed induction")
        expect(response.body).to include("You had 2 ECTs with errors")
      end
    end

    context 'with no valid actions' do
      let(:file_name) { 'no valid actions.csv' }

      let(:data) do
        [{ trn: '7654321', date_of_birth: '1981-06-30' }]
      end

      it "redirects and renders a summary of errors to fix" do
        put ab_batch_action_path(batch)

        expect(response).to redirect_to(ab_batch_action_path(batch))
        follow_redirect!
        expect(response.body).to include("We're processing your CSV file, it could take up to 5 minutes.")

        perform_enqueued_jobs
        get ab_batch_action_path(batch)

        expect(response.body).to include("Your CSV named 'no valid actions.csv' has 1 ECT with errors")
        expect(response.body).to include("Download CSV with error messages included")
        expect(response.body).to include("You'll need to fix these errors before you try again.")
      end
    end
  end
end
