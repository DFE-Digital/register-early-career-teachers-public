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
            dob: '1990-01-01',
            end_date: '2023-12-31',
            number_of_terms: '2.0',
            objective: 'pass',
            error: ''
          },
          {
            trn: '7654321',
            dob: '1980-01-01',
            end_date: '2023-12-31',
            number_of_terms: '2.0',
            objective: 'pass',
            error: ''
          }
        ]
      end

      it 'returns a CSV string' do
        expect(presenter.to_csv).to be_a(String)
      end

      it 'returns a CSV string with the correct headers' do
        expect(presenter.to_csv).to eq("trn,dob,end_date,number_of_terms,objective,error\n")
      end

      context 'and there are failed_submissions' do
        before do
          FactoryBot.create(:pending_induction_submission,
                            appropriate_body:,
                            pending_induction_submission_batch: batch,
                            trn: '1234567',
                            error_message: 'Some error message')

          FactoryBot.create(:pending_induction_submission,
                            appropriate_body:,
                            pending_induction_submission_batch: batch,
                            trn: '7654321')
        end

        it 'returns failed submissions with their errors' do
          expect(presenter.to_csv).to eq(
            <<~CSV_DATA
              trn,dob,end_date,number_of_terms,objective,error
              1234567,1990-01-01,2023-12-31,2.0,pass,Some error message
            CSV_DATA
          )
        end
      end
    end
  end
end
