RSpec.describe GIASImportJob, type: :job do
  describe "#perform" do
    it "runs the importer" do
      importer = instance_spy(GIAS::Importer)

      allow(GIAS::Importer).to receive(:new).and_return(importer)
      allow(importer).to receive(:fetch)

      described_class.new.perform

      expect(GIAS::Importer).to have_received(:new)
      expect(importer).to have_received(:fetch)
    end
  end
end
