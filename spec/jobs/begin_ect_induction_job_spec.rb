RSpec.describe BeginECTInductionJob, type: :job do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:trn) { teacher.trn }
  let(:start_date) { "2024-01-13" }
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }
  let!(:pending_induction_submission_id) { pending_induction_submission.id }
  let(:api_client) { instance_double(TRS::APIClient) }

  before do
    allow(TRS::APIClient).to receive(:new).and_return(api_client)
  end

  describe '#perform' do
    context "when the API call is successful" do
      before do
        allow(api_client).to receive(:begin_induction!)
          .with(trn:, start_date:)
      end

      it "calls the API client with correct parameters" do
        expect(api_client).to receive(:begin_induction!)
          .with(trn:, start_date:)

        described_class.perform_now(
          trn:,
          start_date:,
          pending_induction_submission_id:
        )
      end

      it "it adds a delete_at timestamp 24 hours in the future to the pending induction submission" do
        freeze_time do
          described_class.perform_now(
            trn:,
            start_date:,
            pending_induction_submission_id:
          )

          pending_induction_submission.reload

          expect(pending_induction_submission.delete_at).to eql(24.hours.from_now)
        end
      end
    end
  end
end
