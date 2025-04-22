RSpec.describe ProcessBatchActionJob, type: :job do
  include_context 'fake trs api client'

  let(:author) { FactoryBot.create(:user, name: 'Barry Cryer', email: 'barry@not-a-clue.co.uk') }

  before do
    described_class.perform_now(pending_induction_submission_batch, author.email, author.name)
  end

  describe '#perform' do
    let(:submissions) do
      pending_induction_submission_batch.pending_induction_submissions
    end

    context 'with valid complete data' do
      let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
      let(:pending_induction_submission_batch) do
        FactoryBot.create(:pending_induction_submission_batch, :action,
                          appropriate_body:,
                          data:)
      end

      include_context '3 valid actions'

      it 'creates records for all rows' do
        expect(submissions.count).to eq(3)
      end
    end
  end
end
