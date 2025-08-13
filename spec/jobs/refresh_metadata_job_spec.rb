RSpec.describe RefreshMetadataJob, type: :job do
  describe "#perform" do
    it "calls the Metadata::Manager service with the objects" do
      schools = FactoryBot.create_list(:school, 3)

      manager = instance_double(Metadata::Manager)
      allow(Metadata::Manager).to receive(:new) { manager }
      expect(manager).to receive(:refresh_metadata!).with(schools)

      described_class.new.perform(object_type: School, object_ids: schools.map(&:id))
    end
  end
end
