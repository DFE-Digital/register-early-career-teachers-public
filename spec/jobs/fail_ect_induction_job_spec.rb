RSpec.describe FailECTInductionJob, type: :job do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:trn) { teacher.trn }
  let(:start_date) { Date.parse("2023-11-13") }
  let(:completed_date) { Date.parse("2024-01-13") }
  let(:api_client) { instance_double(TRS::APIClient) }
  let(:refresh_service) { instance_double(Teachers::RefreshTRSAttributes) }

  before do
    allow(TRS::APIClient).to receive(:new).and_return(api_client)
    allow(Teachers::RefreshTRSAttributes)
      .to receive(:new)
      .with(teacher, api_client:)
      .and_return(refresh_service)
    allow(refresh_service).to receive(:refresh!)
  end

  describe '#perform' do
    context "when the API call is successful" do
      before do
        allow(api_client).to receive(:fail_induction!).with(trn:, start_date:, completed_date:)
      end

      it "calls the API client with correct parameters" do
        expect(api_client).to receive(:fail_induction!).with(trn:, start_date:, completed_date:)

        described_class.perform_now(trn:, start_date:, completed_date:)
      end

      it "refreshes the teacher's TRS attributes" do
        expect(refresh_service).to receive(:refresh!)

        described_class.perform_now(trn:, start_date:, completed_date:)
      end
    end
  end
end
