RSpec.describe AppropriateBodies::ProcessBatch::ActionJob, type: :job do
  subject(:perform_action_job) do
    described_class.perform_now(pending_induction_submission_batch, author.email, author.name)
  end

  include_context "test TRS API returns a teacher"

  let(:author) { FactoryBot.create(:user, name: "Barry Cryer", email: "barry@not-a-clue.co.uk") }

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body) }

  let(:pending_induction_submission_batch) do
    FactoryBot.create(:pending_induction_submission_batch, :action, :processing,
                      appropriate_body_period:,
                      data:)
  end

  let(:submissions) do
    pending_induction_submission_batch.pending_induction_submissions
  end

  describe "#perform" do
    context "with valid complete data" do
      include_context "2 valid actions"

      it "creates records for all rows" do
        perform_action_job
        expect(submissions.count).to eq(2)
      end

      it "broadcasts progress as submission records are created" do
        expect {
          perform_action_job
        }.to have_broadcasted_to(
          "batch_progress_stream_#{pending_induction_submission_batch.id}"
        ).from_channel(pending_induction_submission_batch).exactly(8).times
      end
    end

    context "with invalid data" do
      include_context "1 valid and 2 invalid actions"

      it "captures error messages" do
        perform_action_job

        expect(submissions.without_errors.count).to eq(1)
        expect(submissions.with_errors.count).to eq(2)
      end
    end
  end
end
