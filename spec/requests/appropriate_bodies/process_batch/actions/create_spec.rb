RSpec.describe "Appropriate Body bulk actions upload", type: :request do
  include AuthHelper
  include ActionDispatch::TestProcess

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

  let(:csv_file) do
    fixture_file_upload('spec/fixtures/valid_complete_action.csv', 'text/csv')
  end

  let(:batch) do
    PendingInductionSubmissionBatch.for_appropriate_body(appropriate_body).last
  end

  describe 'POST /appropriate-body/bulk/actions' do
    it "enqueues a job" do
      expect {
        post ab_batch_actions_path, params: {
          pending_induction_submission_batch: { csv_file: }
        }
      }.to have_enqueued_job(ProcessBatchActionJob)
    end

    it "redirects" do
      post ab_batch_actions_path, params: {
        pending_induction_submission_batch: { csv_file: }
      }

      expect(response).to redirect_to(ab_batch_action_path(batch))
      follow_redirect!
      expect(response.body).to include("Uploaded CSV data (2 rows)") # debugging data
    end

    context "with an unsupported file type" do
      let(:csv_file) do
        fixture_file_upload('spec/fixtures/invalid_not_a_csv_file.txt', 'text/plain')
      end

      it "shows error message" do
        post ab_batch_actions_path, params: {
          pending_induction_submission_batch: { csv_file: }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("File type must be a CSV")
      end
    end
  end
end
