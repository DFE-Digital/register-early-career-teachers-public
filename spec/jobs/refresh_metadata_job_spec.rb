RSpec.describe RefreshMetadataJob, type: :job do
  describe "#perform" do
    it "calls the Metadata::Manager service with the objects" do
      schools = FactoryBot.create_list(:school, 3)

      manager = instance_double(Metadata::Manager)
      allow(Metadata::Manager).to receive(:new) { manager }
      expect(manager).to receive(:refresh_metadata!).with(a_collection_containing_exactly(*schools), track_changes: false)

      described_class.new.perform(object_type: School, object_ids: schools.map(&:id))
    end

    context "when track_changes is true" do
      it "calls the Metadata::Manager service with track_changes" do
        schools = FactoryBot.create_list(:school, 2)

        manager = instance_double(Metadata::Manager)
        allow(Metadata::Manager).to receive(:new) { manager }
        expect(manager).to receive(:refresh_metadata!).with(schools, track_changes: true)

        described_class.new.perform(object_type: School, object_ids: schools.map(&:id), track_changes: true)
      end
    end
  end
end
