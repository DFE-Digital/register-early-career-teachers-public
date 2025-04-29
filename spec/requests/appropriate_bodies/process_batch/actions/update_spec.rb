RSpec.describe "Appropriate Body bulk actions confirmation", type: :request do
  include AuthHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }
  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :action,
                      appropriate_body:,
                      data:)
  end

  include_context '3 valid actions'

  describe 'PATCH /appropriate-body/bulk/actions/:batch_id' do
    it "enqueues a job" do
      expect {
        put ab_batch_action_path(batch)
      }.to have_enqueued_job(ProcessBatchActionJob).with(batch, user.email, user.name)
    end

    it "redirects" do
      put ab_batch_action_path(batch)

      expect(response).to redirect_to(ab_batch_action_path(batch))
      follow_redirect!
      expect(response.body).to include("Uploaded CSV data (3 rows)") # debugging data
    end
  end
end
