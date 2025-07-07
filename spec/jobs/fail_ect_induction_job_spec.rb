RSpec.describe FailECTInductionJob, type: :job do
  let(:teacher) { create(:teacher) }
  let(:trn) { teacher.trn }
  let(:start_date) { "2023-11-13" }
  let(:completed_date) { "2024-01-13" }
  let(:pending_induction_submission) { create(:pending_induction_submission) }
  let!(:pending_induction_submission_id) { pending_induction_submission.id }
  let(:api_client) { instance_double(TRS::APIClient) }
  let(:refresh_service) { instance_double(Teachers::RefreshTRSAttributes) }

  before do
    allow(TRS::APIClient).to receive(:new).and_return(api_client)
    allow(Teachers::RefreshTRSAttributes).to receive(:new).with(teacher).and_return(refresh_service)
    allow(refresh_service).to receive(:refresh!)
  end

  describe '#perform' do
    context "when the API call is successful" do
      before do
        allow(api_client).to receive(:fail_induction!)
          .with(trn:, start_date:, completed_date:)
      end

      it "calls the API client with correct parameters" do
        expect(api_client).to receive(:fail_induction!)
          .with(trn:, start_date:, completed_date:)

        described_class.perform_now(
          trn:,
          start_date:,
          completed_date:,
          pending_induction_submission_id:
        )
      end

      it "it sets the delete_at timestamp to 24 hours in the future" do
        freeze_time do
          described_class.perform_now(
            trn:,
            start_date:,
            completed_date:,
            pending_induction_submission_id:
          )

          pending_induction_submission.reload

          expect(pending_induction_submission.delete_at).to eql(24.hours.from_now)
        end
      end

      it "refreshes the teacher's TRS attributes" do
        expect(refresh_service).to receive(:refresh!)

        described_class.perform_now(
          trn:,
          start_date:,
          completed_date:,
          pending_induction_submission_id:
        )
      end
    end
  end
end
