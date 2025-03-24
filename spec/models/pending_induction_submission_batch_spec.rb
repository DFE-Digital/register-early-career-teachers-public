RSpec.describe PendingInductionSubmissionBatch do
  subject(:batch) { described_class.new(appropriate_body:) }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe 'associations' do
    it { is_expected.to belong_to(:appropriate_body) }
    it { is_expected.to have_many(:pending_induction_submissions) }
  end

  describe 'file attachment' do
    let(:file_name) { 'valid' }
    let(:file_path) { Rails.root.join("spec/fixtures/#{file_name}.csv") }

    before do
      batch.csv_file.attach(io: File.open(file_path), filename: 'upload.csv', content_type: 'text/csv')
    end

    it { is_expected.to have_one_attached(:csv_file) }
    it { expect(batch.csv_file).to be_attached }
    it { expect(batch.csv_file).to be_an_instance_of(ActiveStorage::Attached::One) }

    describe '#has_valid_csv_headings?' do
      before { batch.save }

      context 'with valid headers' do
        it { is_expected.to have_valid_csv_headings }
      end

      context 'with invalid headers' do
        let(:file_name) { 'invalid_headers' }

        it { is_expected.not_to have_valid_csv_headings }
      end
    end

    describe '#has_unique_trns?' do
      before { batch.save }

      context 'with unique TRNs' do
        it { is_expected.to have_unique_trns }
      end

      context 'with duplicate TRNs' do
        let(:file_name) { 'invalid_duplicate_trns' }

        it { is_expected.not_to have_unique_trns }
      end
    end

    describe '#has_essential_csv_cells?' do
      before { batch.save }

      context 'with all TRNs present' do
        it { is_expected.to have_essential_csv_cells }
      end

      context 'with missing TRNs' do
        let(:file_name) { 'missing_trn' }

        it { is_expected.not_to have_essential_csv_cells }
      end
    end
  end
end
