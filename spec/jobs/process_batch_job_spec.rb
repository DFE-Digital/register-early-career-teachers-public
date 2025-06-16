RSpec.describe ProcessBatchJob, type: :job do
  let(:author) { FactoryBot.build(:user, name: 'Barry Cryer', email: 'barry@not-a-clue.co.uk') }

  let(:appropriate_body) { FactoryBot.build(:appropriate_body) }

  let(:pending_induction_submission_batch) do
    FactoryBot.build(:pending_induction_submission_batch, appropriate_body:)
  end

  describe '#perform' do
    it 'raises an error intended for the subclass' do
      expect {
        described_class.perform_now(pending_induction_submission_batch, author.email, author.name)
      }.to raise_error(NotImplementedError, "You must implement the ProcessBatchJob#batch_service method")
    end
  end
end
