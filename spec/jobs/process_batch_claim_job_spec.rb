RSpec.describe ProcessBatchClaimJob, type: :job do
  include_context 'fake trs api client'

  let(:author) { FactoryBot.create(:user, name: 'Barry Cryer', email: 'barry@not-a-clue.co.uk') }

  before do
    described_class.perform_now(pending_induction_submission_batch, author.email, author.name)
  end

  # TODO: add more coverage to ProcessBatchClaimJob
  # TODO: replace CSV fixture
  describe '#perform' do
    let(:submissions) do
      pending_induction_submission_batch.pending_induction_submissions
    end

    context 'with valid complete data' do
      include_context 'csv file', 'valid_complete', 'claim'

      it 'creates records for all rows' do
        expect(submissions.count).to eq(2)
      end
    end
  end
end
