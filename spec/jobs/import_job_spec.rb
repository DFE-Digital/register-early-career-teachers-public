RSpec.describe ImportJob, type: :job do
  include_context 'fake trs api client'

  before do
    pending_induction_submission_batch.save!

    described_class.perform_now(pending_induction_submission_batch)
  end

  describe '#perform' do
    let(:submissions) do
      pending_induction_submission_batch.pending_induction_submissions
    end

    context 'with valid complete data' do
      include_context 'csv file', 'valid_complete'

      it 'creates records for all rows' do
        expect(submissions.count).to eq(2)
      end
    end

    context 'with valid partial data' do
      include_context 'csv file', 'valid_incomplete'

      it 'creates records for some rows' do
        expect(submissions.count).to eq(2)
      end
    end
  end
end
