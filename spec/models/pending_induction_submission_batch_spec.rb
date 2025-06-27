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
    it { is_expected.to allow_value('completing').for(:batch_status) }
    it { is_expected.to allow_value('completed').for(:batch_status) }
    it { is_expected.to allow_value('failed').for(:batch_status) }
  end

  describe '#recorded_count' do
    it 'stores number of submissions without errors' do
      FactoryBot.create(:pending_induction_submission, :finishing, pending_induction_submission_batch: batch, error_messages: ['Some error'])
      FactoryBot.create(:pending_induction_submission, :claimed, pending_induction_submission_batch: batch)
      FactoryBot.create(:pending_induction_submission, :passed, pending_induction_submission_batch: batch)
      FactoryBot.create(:pending_induction_submission, :failed, pending_induction_submission_batch: batch)
      FactoryBot.create(:pending_induction_submission, :released, pending_induction_submission_batch: batch)

      expect(batch.tally).to eq({ uploaded_count: 1, processed_count: 5, errored_count: 1, released_count: 1, failed_count: 1, passed_count: 1, claimed_count: 1 })
    end
  end

  describe 'metric tallying' do
    it 'tallies row and submission metrics' do
      expect(batch.tally).to eq({ uploaded_count: 1, processed_count: 0, errored_count: 0, released_count: 0, failed_count: 0, passed_count: 0, claimed_count: 0 })

      batch.update!(uploaded_count: 100, processed_count: 99, errored_count: 98, released_count: 97, failed_count: 96, passed_count: 95, claimed_count: 94)

      FactoryBot.create_list(:pending_induction_submission, 1, :finishing, pending_induction_submission_batch: batch, error_messages: ['Some error'])
      FactoryBot.create_list(:pending_induction_submission, 2, :claimed, pending_induction_submission_batch: batch)
      FactoryBot.create_list(:pending_induction_submission, 3, :passed, pending_induction_submission_batch: batch)
      FactoryBot.create_list(:pending_induction_submission, 4, :failed, pending_induction_submission_batch: batch)
      FactoryBot.create_list(:pending_induction_submission, 5, :released, pending_induction_submission_batch: batch)

      expect(batch.tally).to eq({ uploaded_count: 1, processed_count: 15, errored_count: 1, released_count: 5, failed_count: 4, passed_count: 3, claimed_count: 2 })
      batch.completed!
      expect(batch.tally).to eq({ uploaded_count: 100, processed_count: 99, errored_count: 98, released_count: 97, failed_count: 96, passed_count: 95, claimed_count: 94 })
      batch.tally!
      expect(batch.tally).to eq({ uploaded_count: 1, processed_count: 15, errored_count: 1, released_count: 5, failed_count: 4, passed_count: 3, claimed_count: 2 })
      PendingInductionSubmission.delete_all
      expect(batch.tally).to eq({ uploaded_count: 1, processed_count: 15, errored_count: 1, released_count: 5, failed_count: 4, passed_count: 3, claimed_count: 2 })
    end
  end

  describe '#redact!' do
    context 'when the batch is not completed' do
      it 'does nothing' do
        expect(batch.redact!).to be false
        expect(batch.data).not_to be_empty
      end
    end

    context 'when the batch is completed with errors' do
      it 'does nothing' do
        batch.completed!
        FactoryBot.create(:pending_induction_submission, :finishing, pending_induction_submission_batch: batch, error_messages: ['Some error'])
        expect(batch.redact!).to be false
        expect(batch.data).not_to be_empty
      end
    end

    context 'when the batch is completed with no errors' do
      it 'removes JSON parsed from CSV data and the PII within' do
        batch.completed!
        FactoryBot.create_list(:pending_induction_submission, 2, :claimed, pending_induction_submission_batch: batch)
        expect(batch.redact!).to be true
        expect(batch.data).to be_empty
      end
    end
  end
end
