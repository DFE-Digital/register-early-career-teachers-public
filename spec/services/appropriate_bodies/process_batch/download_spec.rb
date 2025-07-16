RSpec.describe AppropriateBodies::ProcessBatch::Download do
  subject(:service) do
    described_class.new(pending_induction_submission_batch:)
  end

  # let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:appropriate_body) { FactoryBot.build(:appropriate_body) }

  let(:pending_induction_submission_batch) do
    # FactoryBot.create(:pending_induction_submission_batch, :action,
    FactoryBot.build(:pending_induction_submission_batch, :action,
                     appropriate_body:,
                     data:)
  end

  describe '#to_csv' do
    context 'when no CSV data has been saved' do
      let(:data) { nil }

      it 'raises an error' do
        expect { service.to_csv }.to raise_error(AppropriateBodies::ProcessBatch::Download::MissingCSVDataError)
      end
    end

    context 'when all CSV data has been redacted' do
      let(:data) { [] }

      it 'raises an error' do
        expect { service.to_csv }.to raise_error(AppropriateBodies::ProcessBatch::Download::MissingCSVDataError)
      end
    end

    context 'when there is persisted CSV data' do
      let(:data) do
        [
          {
            trn: '1234567',
            date_of_birth: '',
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
        expect(service.to_csv).to be_a(String)
      end

      context 'without failed submissions' do
        it 'returns CSV content with the correct headers, quoted cells, and no rows' do
          expect(service.to_csv).to eq(
            <<~CSV_DATA
              "TRN","Date of birth","Induction period end date","Number of terms","Outcome","Error message"
            CSV_DATA
          )
        end
      end

      context 'with failed submissions' do
        before do
          FactoryBot.create(:pending_induction_submission,
                            appropriate_body:,
                            pending_induction_submission_batch:,
                            trn: '1234567',
                            error_messages: [
                              'error one',
                              'error two',
                              'error three',
                              'error four'
                            ])

          FactoryBot.create(:pending_induction_submission,
                            appropriate_body:,
                            pending_induction_submission_batch:,
                            trn: '7654321')
        end

        it 'returns only failed submissions with their errors as a sentence' do
          expect(service.to_csv).to eq(
            <<~CSV_DATA
              "TRN","Date of birth","Induction period end date","Number of terms","Outcome","Error message"
              "1234567","","2023-12-31","2.0","pass","error one, error two, error three, and error four"
            CSV_DATA
          )
        end
      end
    end
  end
end
