RSpec.describe Teachers::SyncTeacherWithTRSJob, type: :job do
  describe "#perform" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:refresh_service) { instance_double(Teachers::RefreshTRSAttributes) }

    it "calls the RefreshTRSAttributes service with the correct teacher" do
      allow(Teachers::RefreshTRSAttributes).to receive(:new).with(teacher).and_return(refresh_service)
      expect(refresh_service).to receive(:refresh!)

      described_class.perform_now(teacher:)
    end

    it "uses the trs_sync queue" do
      expect(described_class.queue_name).to eq("trs_sync")
    end
  end
end
