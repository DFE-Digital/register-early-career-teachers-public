RSpec.describe PendingInductionSubmissionBatch do
  subject(:batch) { FactoryBot.build(:pending_induction_submission_batch, :claim) }

  describe "associations" do
    it { is_expected.to belong_to(:appropriate_body) }
    it { is_expected.to have_many(:pending_induction_submissions) }
  end

  describe "scopes" do
    describe ".for_appropriate_body" do
      it "returns batched submissions for the specified appropriate body" do
        expect(described_class.for_appropriate_body(456).to_sql).to end_with(%( WHERE "pending_induction_submission_batches"."appropriate_body_id" = 456))
      end
    end
  end

  describe "class methods" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

    describe ".new_claim_for" do
      subject(:claim) { described_class.new_claim_for(appropriate_body:) }

      it 'creates a batch claim' do
        expect(claim).to be_a(PendingInductionSubmissionBatch)
        expect(claim).to be_claim
        expect(claim).to be_pending
        expect(claim.appropriate_body).to eq(appropriate_body)
      end
    end

    describe ".new_action_for" do
      subject(:action) { described_class.new_action_for(appropriate_body:) }

      it 'creates a batch action' do
        expect(action).to be_a(PendingInductionSubmissionBatch)
        expect(action).to be_action
        expect(action).to be_pending
        expect(action.appropriate_body).to eq(appropriate_body)
      end
    end

    describe ".build_row_class" do
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
        row = row_class.new(foo: "André", bar: "Zoë", baz: "Ştefan")
        expect(row.to_a).to eq(%w[André Zoë Ştefan])
      end
    end
  end

  describe "validations" do
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
      subject(:batch) { FactoryBot.build(:pending_induction_submission_batch, :claim, csv_file:) }

      describe "#csv_mime_type" do
        let(:csv_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/foo.txt'), 'text/plain') }

        specify do
          expect(batch).not_to be_valid
          expect(batch.errors[:csv_file]).to include("File type must be a CSV")
        end
      end

      describe "#wrong_headers" do # softened rules so order doesn't matter - still TBC
        let(:csv_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/claims/invalid_missing_columns.csv'), 'text/csv') }

        specify do
          batch.save!
          expect(batch).not_to be_valid(:uploaded)
          expect(batch.errors[:csv_file]).to include("CSV file contains unsupported columns")
        end
      end

      describe "#unique_trns" do
        let(:csv_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/claims/invalid_duplicate_trns.csv'), 'text/csv') }

        specify do
          batch.save!
          expect(batch).not_to be_valid(:uploaded)
          expect(batch.errors[:csv_file]).to include("CSV file contains duplicate TRNs")
        end
      end

      describe "#missing_trns" do
        let(:csv_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/claims/invalid_missing_trn.csv'), 'text/csv') }

        specify do
          batch.save!
          expect(batch).not_to be_valid(:uploaded)
          expect(batch.errors[:csv_file]).to include("CSV file contains missing TRNs")
        end
      end

      describe "#missing_dobs" do
        let(:csv_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/claims/invalid_missing_dob.csv'), 'text/csv') }

        specify do
          batch.save!
          expect(batch).not_to be_valid(:uploaded)
          expect(batch.errors[:csv_file]).to include("CSV file contains missing dates of birth")
        end
      end

      describe "#iso8601_date" do
        let(:csv_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/claims/invalid_date_format.csv'), 'text/csv') }

        specify do
          batch.save!
          expect(batch).not_to be_valid(:uploaded)
          expect(batch.errors[:csv_file]).to include("CSV file contains unsupported date format")
        end
      end
    end
  end
end
