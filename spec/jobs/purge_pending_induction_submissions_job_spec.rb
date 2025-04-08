RSpec.describe PurgePendingInductionSubmissionsJob, type: :job do
  describe "#perform" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

    it "deletes pending induction submissions with delete_at in the past" do
      # submissions that should be deleted
      past_submissions = FactoryBot.create_list(
        :pending_induction_submission,
        3,
        appropriate_body:,
        delete_at: 1.hour.ago
      )

      # submissions with delete_at in the future
      FactoryBot.create_list(
        :pending_induction_submission,
        2,
        appropriate_body:,
        delete_at: 1.hour.from_now
      )

      # submissions with no delete_at
      FactoryBot.create_list(
        :pending_induction_submission,
        2,
        appropriate_body:,
        delete_at: nil
      )

      expect {
        described_class.perform_now
      }.to change(PendingInductionSubmission, :count).by(-3)

      # Verify the right records were deleted
      past_submission_ids = past_submissions.map(&:id)
      remaining_submission_ids = PendingInductionSubmission.pluck(:id)

      expect(remaining_submission_ids).not_to include(*past_submission_ids)
    end
  end
end
