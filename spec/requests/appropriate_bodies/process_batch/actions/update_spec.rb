RSpec.describe "Appropriate Body bulk actions confirmation", type: :request do
  include ActiveJob::TestHelper

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body) }
  let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body: appropriate_body_period) }
  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :action, :processed,
                      appropriate_body_period:,
                      data:,
                      file_name:)
  end

  include_context "test TRS API returns a teacher"

  describe "PATCH /appropriate-body/bulk/actions/:batch_id" do
    context "with only valid actions" do
      include_context "2 valid actions"

      it "enqueues a job" do
        expect {
          put ab_batch_action_path(batch)
        }.to have_enqueued_job(AppropriateBodies::ProcessBatch::ActionJob).with(batch, user.email, user.name).exactly(1).times
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

      it "redirects" do
        put ab_batch_action_path(batch)
        expect(response).to redirect_to(ab_batch_action_path(batch))
        follow_redirect!
        expect(response.body).to include("Outcomes successfully recorded")
      end

      it "prevents duplicates" do
        expect {
          put ab_batch_action_path(batch)
        }.to have_enqueued_job(AppropriateBodies::ProcessBatch::ActionJob).with(batch, user.email, user.name)

        expect {
          put ab_batch_action_path(batch)
        }.not_to have_enqueued_job(AppropriateBodies::ProcessBatch::ActionJob)
      end
    end
  end
end
