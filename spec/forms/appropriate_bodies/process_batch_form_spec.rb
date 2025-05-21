RSpec.describe AppropriateBodies::ProcessBatchForm, type: :model do
  subject(:form) { described_class.from_uploaded_file(headers:, csv_file:) }

  let(:headers) { BatchRows::ACTION_CSV_HEADINGS }

  let(:csv_content) do
    <<~CSV
      TRN,Date of birth,Induction period end date,Number of terms,Outcome
      1234567,2000-01-01,2023-12-31,1,Pass
      2345678,2001-02-02,2024-12-31,2,Fail
    CSV
  end

  let(:content_type) { 'text/csv' }
  let(:csv_file_size) { 50.kilobytes }

  let(:csv_file) do
    instance_double(ActionDispatch::Http::UploadedFile,
                    content_type:,
                    size: csv_file_size,
                    read: csv_content,
                    original_filename: 'test.csv')
  end

  context 'when the attached file is valid' do
    specify do
      expect(form).to be_valid
      expect(form.to_a).to eq([
        { trn: '1234567', date_of_birth: '2000-01-01', finished_on: '2023-12-31', number_of_terms: '1', outcome: 'Pass', },
        { trn: '2345678', date_of_birth: '2001-02-02', finished_on: '2024-12-31', number_of_terms: '2', outcome: 'Fail' }
      ])
    end

    describe 'contains cell padding' do
      let(:csv_content) do
        <<~CSV
          TRN,Date of birth,Induction period end date,Number of terms,Outcome
            1234567  ,  2000-01-01  ,  2023-12-31  , 1 , Pass
            2345678  ,  2001-02-02  ,  2024-12-31  , 2 , Fail
        CSV
      end

      specify do
        expect(form).to be_valid
        expect(form.to_a).to eq([
          { trn: '1234567', date_of_birth: '2000-01-01', finished_on: '2023-12-31', number_of_terms: '1', outcome: 'Pass', },
          { trn: '2345678', date_of_birth: '2001-02-02', finished_on: '2024-12-31', number_of_terms: '2', outcome: 'Fail' }
        ])
      end
    end

    describe '2nd attempt containing error messages column' do
      let(:csv_content) do
        <<~CSV
          TRN,Date of birth,Induction period end date,Number of terms,Outcome,Error message
          1234567,2000-01-01,2023-12-31,1,Pass,An error was fixed
          2345678,2001-02-02,2024-12-31,2,Fail,An error was fixed
        CSV
      end

      specify do
        expect(form).to be_valid
        expect(form.to_a).to eq([
          { trn: '1234567', date_of_birth: '2000-01-01', finished_on: '2023-12-31', number_of_terms: '1', outcome: 'Pass', error: 'An error was fixed' },
          { trn: '2345678', date_of_birth: '2001-02-02', finished_on: '2024-12-31', number_of_terms: '2', outcome: 'Fail', error: 'An error was fixed' }
        ])
      end
    end

    describe 'asymmetrical data with uneven rows' do
      let(:csv_content) do
        <<~CSV
          TRN,Date of birth,Induction period end date,Number of terms,Outcome
          1234567,2000-01-01,2023-12-31,1,Pass,,,
        CSV
      end

      specify do
        expect(form).to be_valid
        expect(form.to_a).to eq([
          { trn: '1234567', date_of_birth: '2000-01-01', finished_on: '2023-12-31', number_of_terms: '1', outcome: 'Pass' }
        ])
      end
    end

    describe 'formatting errors and blank cells' do
      let(:csv_content) do
        <<~CSV
          TRN,Date of birth,Induction period end date,Number of terms,Outcome
          123456789X,01/01/2000,2023-12-31,,PASSED
        CSV
      end

      specify do
        expect(form).to be_valid
        expect(form.to_a).to eq([
          { trn: '123456789X', date_of_birth: '01/01/2000', finished_on: '2023-12-31', outcome: 'PASSED' }
        ])
      end
    end
  end

  context 'when the attached file is invalid' do
    describe '#csv_mime_type' do
      let(:content_type) { 'text/plain' }

      specify do
        expect(form).not_to be_valid
        expect(form.errors[:csv_file]).to include('The selected file must be a CSV')
      end
    end

    describe '#csv_file_size' do
      let(:csv_file_size) { 101.kilobytes }

      specify do
        expect(form).not_to be_valid
        expect(form.errors[:csv_file]).to include('File size must be less than 100KB')
      end
    end

    describe '#wrong_headers' do
      let(:headers) do
        {
          trn: 'TRN',
          date_of_birth: 'Date of birth',
        }
      end

      specify do
        expect(form).not_to be_valid
        expect(form.errors[:csv_file]).to include('The selected file must follow the template')
      end
    end

    describe '#unique_trns' do
      let(:csv_content) do
        <<~CSV
          TRN,Date of birth,Induction period end date,Number of terms,Outcome,Error message
          1234567,2000-01-01,2023-12-31,1,pass
          1234567,2001-02-02,2024-12-31,2,pass
        CSV
      end

      specify do
        expect(form).not_to be_valid
        expect(form.errors[:csv_file]).to include('The selected file has duplicate ECTs')
      end
    end

    describe '#row_count' do
      context 'with too many rows' do
        let(:csv_content) do
          <<~CSV
            TRN,Date of birth,Induction period end date,Number of terms,Outcome,Error message
              1234567,2001-02-02,2024-12-31,1,pass
              2345678,2001-02-02,2024-12-31,2,pass
              3456789,2001-02-02,2024-12-31,2,pass
              4567890,2001-02-02,2024-12-31,2,pass
              0987654,2001-02-02,2024-12-31,2,pass
              9876543,2001-02-02,2024-12-31,2,pass
              8765432,2001-02-02,2024-12-31,2,pass
              7654321,2001-02-02,2024-12-31,2,pass
          CSV
        end

        specify do
          stub_const('AppropriateBodies::ProcessBatchForm::MAX_ROW_SIZE', 5)
          expect(form).not_to be_valid
          expect(form.errors[:csv_file]).to include('The selected file must have fewer than 5 rows')
        end
      end
    end

    context 'with too few rows' do
      let(:csv_content) do
        <<~CSV
          TRN,Date of birth,Induction period end date,Number of terms,Outcome,Error message
        CSV
      end

      specify do
        expect(form).not_to be_valid
        expect(form.errors[:csv_file]).to include('The selected file is empty')
      end
    end
  end
end
