RSpec.describe GIASImportJob, type: :job do
  let(:importer) { instance_spy(GIAS::Importer) }
  let(:reconciler) { instance_spy(GIAS::Reconcile) }

  before do
    allow(GIAS::Importer).to receive(:new).and_return(importer)
    allow(importer).to receive(:fetch).and_return(%w[urn1 urn2])
    allow(GIAS::Reconcile).to receive(:new).and_return(reconciler)
    allow(reconciler).to receive(:call)
  end

  describe "#perform" do
    it "runs the importer and reconciler" do
      described_class.new.perform

      expect(GIAS::Importer).to have_received(:new)
      expect(importer).to have_received(:fetch)
      expect(GIAS::Reconcile).to have_received(:new).with(%w[urn1 urn2])
      expect(reconciler).to have_received(:call)
    end
  end
end
