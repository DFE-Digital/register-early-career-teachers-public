RSpec.describe BatchAction do
  subject(:batch) { described_class.new(appropriate_body:) }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe 'associations' do
    it { is_expected.to belong_to(:appropriate_body) }
    it { is_expected.to have_many(:pending_induction_submissions) }
  end

  describe 'file attachment' do
    let(:file_name) { 'valid_complete' }
    let(:file_path) { Rails.root.join("spec/fixtures/factoried/#{file_name}.csv") }

    before do
      batch.csv_file.attach(io: File.open(file_path), filename: 'upload.csv', content_type: 'text/csv')
      batch.save!
    end

    it { is_expected.to have_one_attached(:csv_file) }
    it { expect(batch.csv_file).to be_attached }
    it { expect(batch.csv_file).to be_an_instance_of(ActiveStorage::Attached::One) }

    describe '#data' do
      it {
        expect(batch.data.to_a).to eq([
          %w[trn dob end_date number_of_terms objective error],
          ["1234567", "30-06-1981", nil, nil, nil, nil],
          ["7654321", "30-06-1981", nil, nil, nil, nil]
        ])
      }
    end

    describe '#rows' do
      skip 'wip'
    end

    describe '#has_valid_csv_headings?' do
      context 'with valid headers' do
        it { is_expected.to have_valid_csv_headings }
      end

      context 'with invalid headers' do
        let(:file_name) { 'invalid_missing_columns' }

        it { is_expected.not_to have_valid_csv_headings }
      end
    end

    describe '#has_unique_trns?' do
      context 'with unique TRNs' do
        it { is_expected.to have_unique_trns }
      end

      context 'with duplicate TRNs' do
        let(:file_name) { 'invalid_duplicate_trns' }

        it { is_expected.not_to have_unique_trns }
      end
    end

    describe '#has_essential_csv_cells?' do
      context 'with all TRNs present' do
        it { is_expected.to have_essential_csv_cells }
      end

      context 'with missing TRNs' do
        let(:file_name) { 'invalid_missing_trn' }

        it { is_expected.not_to have_essential_csv_cells }
      end
    end
  end
end
