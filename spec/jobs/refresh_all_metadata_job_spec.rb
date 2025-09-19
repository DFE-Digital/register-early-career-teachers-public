RSpec.describe RefreshAllMetadataJob, type: :job do
  describe "#perform" do
    it "calls Metadata::Manager.refresh_all_metadata!" do
      expect(Metadata::Manager).to receive(:refresh_all_metadata!).with(async: true, track_changes: true)

      described_class.new.perform
    end
  end
end
