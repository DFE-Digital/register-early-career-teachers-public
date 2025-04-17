RSpec.describe PendingInductionSubmissionBatch do
  subject(:batch) { FactoryBot.build(:pending_induction_submission_batch, :claim) }

  describe 'associations' do
    it { is_expected.to belong_to(:appropriate_body) }
    it { is_expected.to have_many(:pending_induction_submissions) }
  end

  describe "scopes" do
    describe ".for_appropriate_body" do
      let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

      let!(:batch1) { FactoryBot.create(:pending_induction_submission_batch, :claim, appropriate_body:) }
      let!(:batch2) { FactoryBot.create(:pending_induction_submission_batch, :action, appropriate_body:) }
      let!(:batch3) { FactoryBot.create(:pending_induction_submission_batch, :claim, appropriate_body:) }

      it "returns batched submissions for the specified appropriate body" do
        expect(described_class.for_appropriate_body(appropriate_body)).to contain_exactly(batch1, batch2, batch3)
      end
    end
  end

  describe 'callbacks' do
    describe '#data_from_csv' do
      it 'persists data from disk to database and deletes attachment' do
        expect(batch.csv_file).to be_attached
        expect(batch.data).to be_nil

        batch.save!

        expect(batch.csv_file).not_to be_attached
        expect(batch.data).not_to be_nil
      end
    end
  end

  describe 'class methods' do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

    describe '.new_claim_for' do
      subject(:claim) { described_class.new_claim_for(appropriate_body:) }

      it 'creates a batch claim' do
        expect(claim).to be_a(PendingInductionSubmissionBatch)
        expect(claim).to be_claim
        expect(claim).to be_pending
        expect(claim.appropriate_body).to eq(appropriate_body)
      end
    end

    describe '.new_action_for' do
      subject(:action) { described_class.new_action_for(appropriate_body:) }

      it 'creates a batch action' do
        expect(action).to be_a(PendingInductionSubmissionBatch)
        expect(action).to be_action
        expect(action).to be_pending
        expect(action.appropriate_body).to eq(appropriate_body)
      end
    end

    describe '.build_row_class' do
      subject(:row_class) { described_class.build_row_class(%i[foo bar baz]) }

      it 'errors if the wrong attributes are used' do
        expect { row_class.new }.to raise_error('missing keywords: :foo, :bar, :baz')
      end

      it 'creates an enumerable Data class to encapsulate CSV row cells' do
        row = row_class.new(foo: 'foo', bar: 'bar', baz: 'baz')
        expect(row).to be_a(row_class)
        expect(row).to be_a(Enumerable)
        expect(row.to_a).to eq(%w[foo bar baz])
        expect(row).to respond_to(:foo)
        expect(row).not_to respond_to(:buz)
      end

      it 'string encodes values' do
        row = row_class.new(foo: 'André', bar: 'Zoë', baz: 'Ştefan')
        expect(row.to_a).to eq(%w[André Zoë Ştefan])
      end
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:batch_type) }
    it { is_expected.to allow_value('action').for(:batch_type) }
    it { is_expected.to allow_value('claim').for(:batch_type) }

    it { is_expected.to validate_presence_of(:batch_status) }
    it { is_expected.to allow_value('pending').for(:batch_status) }
    it { is_expected.to allow_value('processing').for(:batch_status) }
    it { is_expected.to allow_value('processed').for(:batch_status) }
    it { is_expected.to allow_value('completed').for(:batch_status) }
    it { is_expected.to allow_value('failed').for(:batch_status) }

    context 'when the attached file is invalid' do
      subject(:batch) { FactoryBot.build(:pending_induction_submission_batch, :action) }

      describe '#csv_mime_type' do
        before do
          allow(batch.csv_file).to receive(:content_type).and_return('text/plain')
        end

        specify do
          expect(batch).not_to be_valid
          expect(batch.errors[:csv_file]).to include('File type must be a CSV')
        end
      end

      describe '#csv_file_size' do
        before do
          allow(batch.csv_file).to receive(:byte_size).and_return(2.megabytes)
        end

        specify do
          expect(batch).not_to be_valid
          expect(batch.errors[:csv_file]).to include('File size must be less than 1MB')
        end
      end

      describe '#wrong_headers' do
        let(:parsed_csv) do
          double('CSV::Table', headers: %w[trn dob], each: [], count: 0)
        end

        before do
          allow(batch).to receive(:from_csv).and_return(parsed_csv)
        end

        specify do
          batch.save!
          expect(batch).not_to be_valid(:uploaded)
          expect(batch.errors[:csv_file]).to include('CSV file contains unsupported columns')
        end
      end

      describe '#unique_trns' do
        let(:duplicate_rows) do
          [
            { trn: '1234567', dob: '', end_date: '', number_of_terms: '', objective: '', error: '' },
            { trn: '1234567', dob: '', end_date: '', number_of_terms: '', objective: '', error: '' },
          ]
        end

        let(:parsed_csv) do
          double('CSV::Table', headers: %w[trn], each: duplicate_rows, count: 2)
        end

        before do
          allow(batch).to receive(:from_csv).and_return(parsed_csv)
        end

        specify do
          batch.save!
          expect(batch).not_to be_valid(:uploaded)
          expect(batch.errors[:csv_file]).to include('CSV file contains duplicate TRNs')
        end
      end

      describe '#row_count' do
        let(:parsed_csv) do
          double('CSV::Table', headers: [], each: [], count: 1001)
        end

        before do
          allow(batch).to receive(:from_csv).and_return(parsed_csv)
        end

        specify do
          batch.save!
          expect(batch).not_to be_valid(:uploaded)
          expect(batch.errors[:csv_file]).to include('CSV file contains too many rows')
        end
      end
    end
  end
end
