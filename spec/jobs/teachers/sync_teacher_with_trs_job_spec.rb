RSpec.describe Teachers::SyncTeacherWithTRSJob, type: :job do
  describe "#perform" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:api_client) { instance_double(TRS::APIClient) }
    let(:refresh_service) { instance_double(Teachers::RefreshTRSAttributes) }

    before do
      allow(TRS::APIClient).to receive(:new).and_return(api_client)
      allow(Teachers::RefreshTRSAttributes)
        .to receive(:new)
        .with(teacher, api_client:)
        .and_return(refresh_service)
    end

    it "calls the RefreshTRSAttributes service with the correct teacher" do
      expect(refresh_service).to receive(:refresh!)

      described_class.perform_now(teacher:)
    end

    it "uses the trs_sync queue" do
      expect(described_class.queue_name).to eq("trs_sync")
    end
  end
end
