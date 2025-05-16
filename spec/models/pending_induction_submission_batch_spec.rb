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
    it { is_expected.to allow_value('completed').for(:batch_status) }
    it { is_expected.to allow_value('failed').for(:batch_status) }
  end
end
