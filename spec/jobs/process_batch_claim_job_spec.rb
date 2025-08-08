RSpec.describe ProcessBatchClaimJob, type: :job do
  include_context 'test trs api client'

  let(:author) { FactoryBot.create(:user, name: 'Barry Cryer', email: 'barry@not-a-clue.co.uk') }
  let(:web_request_uuid) { SecureRandom.uuid }

  describe '#perform' do
    let(:submissions) do
      pending_induction_submission_batch.pending_induction_submissions
    end

    context 'with valid complete data' do
      let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
      let(:pending_induction_submission_batch) do
        FactoryBot.create(:pending_induction_submission_batch, :claim,
                          appropriate_body:,
                          data:)
      end

      include_context '2 valid claims'

      it 'creates records for all rows' do
        described_class.perform_now(pending_induction_submission_batch, author.email, author.name, web_request_uuid)
        expect(submissions.count).to eq(2)
      end

      it 'broadcasts progress as submission records are created' do
        expect {
          described_class.perform_now(pending_induction_submission_batch, author.email, author.name, web_request_uuid)
        }.to have_broadcasted_to(
          "batch_progress_stream_#{pending_induction_submission_batch.id}"
        ).from_channel(pending_induction_submission_batch).exactly(10).times
      end
    end
  end
end
