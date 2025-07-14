RSpec.describe ProcessBatchActionJob, type: :job do
  include_context 'test trs api client'

  let(:author) { FactoryBot.create(:user, name: 'Barry Cryer', email: 'barry@not-a-clue.co.uk') }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe '#perform' do
    let(:submissions) do
      pending_induction_submission_batch.pending_induction_submissions
    end

    context 'with valid complete data' do
      let(:pending_induction_submission_batch) do
        FactoryBot.create(:pending_induction_submission_batch, :action,
                          appropriate_body:,
                          data:)
      end

      include_context '3 valid actions'

      it 'creates records for all rows' do
        described_class.perform_now(pending_induction_submission_batch, author.email, author.name)
        expect(submissions.count).to eq(3)
      end

      it 'broadcasts progress as submission records are created' do
        expect {
          described_class.perform_now(pending_induction_submission_batch, author.email, author.name)
        }.to have_broadcasted_to(
          "batch_progress_stream_#{pending_induction_submission_batch.id}"
        ).from_channel(pending_induction_submission_batch).exactly(11).times
      end
    end
  end
end
