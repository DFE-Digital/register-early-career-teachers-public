RSpec.describe AppropriateBodies::ProcessBatchForm, type: :model do
  subject(:form) { described_class.from_uploaded_file(headers:, csv_file:) }

  let(:headers) { %w[trn dob end_date number_of_terms objective] }

  let(:csv_content) do
    <<~CSV
      trn,dob,end_date,number_of_terms,objective
      1234567,2000-01-01,2023-12-31,1,Test Objective
      2345678,2001-02-02,2024-12-31,2,Another Objective
    CSV
  end

  let(:content_type) { 'text/csv' }
  let(:csv_file_size) { 1.megabyte }

  # https://api.rubyonrails.org/classes/ActionDispatch/Http/UploadedFile.html
  let(:csv_file) do
    instance_double(ActionDispatch::Http::UploadedFile,
                    content_type:,
                    size: csv_file_size,
                    read: csv_content)
  end

  context 'when the attached file is invalid' do
    describe '#csv_mime_type' do
      let(:content_type) { 'text/plain' }

      specify do
        expect(form).not_to be_valid
        expect(form.errors[:csv_file]).to include('File type must be a CSV')
      end
    end

    describe '#csv_file_size' do
      let(:csv_file_size) { 100.megabytes }

      specify do
        expect(form).not_to be_valid
        expect(form.errors[:csv_file]).to include('File size must be less than 1MB')
      end
    end

    describe '#wrong_headers' do
      let(:headers) { %w[trn dob] }

      specify do
        expect(form).not_to be_valid
        expect(form.errors[:csv_file]).to include('CSV file contains unsupported columns')
      end
    end

    describe '#unique_trns' do
      let(:csv_content) do
        <<~CSV
          trn,dob,end_date,number_of_terms,objective
          1234567,2000-01-01,2023-12-31,1,pass
          1234567,2001-02-02,2024-12-31,2,pass
        CSV
      end

      specify do
        expect(form).not_to be_valid
        expect(form.errors[:csv_file]).to include('CSV file contains duplicate TRNs')
      end
    end

    describe '#row_count' do
      let(:csv_content) do
        <<~CSV
          trn,dob,end_date,number_of_terms,objective
          1234567,2000-01-01,2023-12-31,1,pass
          2345678,2001-02-02,2024-12-31,2,pass
          2345678,2001-02-02,2024-12-31,2,pass
          2345678,2001-02-02,2024-12-31,2,pass
          2345678,2001-02-02,2024-12-31,2,pass
          2345678,2001-02-02,2024-12-31,2,pass
          2345678,2001-02-02,2024-12-31,2,pass
          2345678,2001-02-02,2024-12-31,2,pass
        CSV
      end

      specify do
        expect(form).not_to be_valid
        expect(form.errors[:csv_file]).to include('CSV file contains too many rows')
      end
    end
  end
end
