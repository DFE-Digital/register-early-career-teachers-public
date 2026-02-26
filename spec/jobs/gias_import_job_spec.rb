RSpec.describe GIASImportJob, type: :job do
  describe "#perform" do
    it "runs the importer with school auto creation disabled" do
      importer = instance_spy(GIAS::Importer)

      allow(GIAS::Importer).to receive(:new).and_return(importer)

      described_class.new.perform

      expect(GIAS::Importer).to have_received(:new).with(auto_create_school: false)
      expect(importer).to have_received(:fetch)
    end
  end
end
