RSpec.describe PendingInductionSubmissionBatchPresenter do
  subject(:presenter) { described_class.new(batch) }

  let(:batch) { FactoryBot.build(:pending_induction_submission_batch, :action) }

  describe 'decorated model methods' do
    it '#batch_type' do
      expect(presenter.batch_type).to eq('action')
    end

    it '#batch_status' do
      expect(presenter.batch_status).to eq('pending')
    end
  end

  describe '#to_csv' do
    context 'when there is no persisted CSV data' do
      let(:batch) { FactoryBot.build(:pending_induction_submission_batch, :action, data:) }
      let(:data) { nil }

      it 'raises an error' do
        expect { presenter.to_csv }.to raise_error(PendingInductionSubmissionBatchPresenter::MissingCSVDataError)
      end
    end

    context 'when there is persisted CSV data' do
      let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
      let(:batch) do
        FactoryBot.create(:pending_induction_submission_batch, :action,
                          appropriate_body:,
                          data:)
      end

      let(:data) do
        [
          {
            trn: '1234567',
            date_of_birth: '1990-01-01',
            finished_on: '2023-12-31',
            number_of_terms: '2.0',
            outcome: 'pass',
            error: ''
          },
          {
            trn: '7654321',
            date_of_birth: '1980-01-01',
            finished_on: '2023-12-31',
            number_of_terms: '2.0',
            outcome: 'pass',
            error: ''
          }
        ]
      end

      it 'returns a CSV string' do
        expect(presenter.to_csv).to be_a(String)
      end

      it 'returns a CSV string with the correct headers and no rows' do
        expect(presenter.to_csv).to eq("TRN,Date of birth,Induction end date,Number of terms,Outcome,Error message\n")
      end

      context 'and there are failed_submissions' do
        before do
          FactoryBot.create(:pending_induction_submission,
                            appropriate_body:,
                            pending_induction_submission_batch: batch,
                            trn: '1234567',
                            error_messages: [
                              'error one',
                              'error two',
                              'error three',
                              'error four'
                            ])

          FactoryBot.create(:pending_induction_submission,
                            appropriate_body:,
                            pending_induction_submission_batch: batch,
                            trn: '7654321')
        end

        it 'returns only failed submissions with their errors as a sentence' do
          expect(presenter.to_csv).to eq(
            <<~CSV_DATA
              TRN,Date of birth,Induction end date,Number of terms,Outcome,Error message
              1234567,1990-01-01,2023-12-31,2.0,pass,"error one, error two, error three, and error four"
            CSV_DATA
          )
        end
      end
    end
  end
end
