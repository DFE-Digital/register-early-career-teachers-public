RSpec.describe PendingInductionSubmissionBatch do
  describe "associations" do
    it { is_expected.to belong_to(:appropriate_body) }
    it { is_expected.to have_many(:pending_induction_submissions) }
  end

  describe "scopes" do
    describe ".for_appropriate_body" do
      it "returns batched submissions for the specified appropriate body" do
        expect(described_class.for_appropriate_body(456).to_sql).to end_with(%( WHERE "pending_induction_submission_batches"."appropriate_body_id" = 456))
      end
    end
  end
end
