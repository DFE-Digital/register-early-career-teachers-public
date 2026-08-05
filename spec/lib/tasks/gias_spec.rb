describe "GIAS tasks" do
  let(:importer) { instance_double(GIAS::Importer) }
  let(:reconciler) { instance_double(GIAS::Reconcile) }
  let(:logger) { instance_double(Logger, info: true) }
  let(:urns_to_reconcile) { [12_345, 67_890] }
  let(:unreconcilable_urns) { [] }

  before do
    Rake::Task["gias:import_and_reconcile"].reenable
    Rake::Task["gias:reconcile"].reenable

    allow(Logger).to receive(:new).with($stdout).and_return(logger)
    allow(logger).to receive(:warn)
    allow(GIAS::Importer).to receive(:new).and_return(importer)
    allow(importer).to receive(:fetch).and_return(urns_to_reconcile)
    allow(GIAS::Reconcile).to receive(:new).with(urns_to_reconcile).and_return(reconciler)
    allow(reconciler).to receive(:call).and_return(unreconcilable_urns)
  end

  describe "gias:import" do
    it "imports without reconciliation" do
      expect(importer).to receive(:fetch)
      expect(reconciler).not_to receive(:call)
      expect(logger).to receive(:info).with("GIAS schools data import complete!")

      Rake::Task["gias:import"].invoke
    end
  end

  describe "gias:import_and_reconcile" do
    it "imports and reconciles" do
      expect(importer).to receive(:fetch)
      expect(reconciler).to receive(:call)
      expect(logger).to receive(:info).with("GIAS schools data import complete, 2 schools to reconcile")
      expect(logger).to receive(:info).with("GIAS schools data import and reconciliation complete!")

      Rake::Task["gias:import_and_reconcile"].invoke
    end

    context "when there are unreconcilable URNs" do
      let(:unreconcilable_urns) { [67_890] }

      it "logs a warning" do
        expect(importer).to receive(:fetch)
        expect(reconciler).to receive(:call)
        expect(logger).to receive(:info).with("GIAS schools data import complete, 2 schools to reconcile")
        expect(logger).to receive(:warn).with("The following URNs could not be reconciled: 67890")
        expect(logger).to receive(:info).with("GIAS schools data import and reconciliation complete!")

        Rake::Task["gias:import_and_reconcile"].invoke
      end
    end
  end

  describe "gias:reconcile" do
    it "reconciles with provided URNs" do
      expect(reconciler).to receive(:call)
      expect(logger).to receive(:info).with("Reconciling GIAS schools data for 2 URNs")
      expect(logger).to receive(:info).with("GIAS schools data reconciliation complete!")

      Rake::Task["gias:reconcile"].invoke("12345,67890")
    end

    context "when no URNs are provided" do
      it "logs a warning" do
        expect(logger).to receive(:warn).with("No URNs provided. Usage: rake gias:reconcile[12345,67890]")

        Rake::Task["gias:reconcile"].invoke("")
      end
    end

    context "when there are unreconcilable URNs" do
      let(:unreconcilable_urns) { [67_890] }

      it "logs a warning" do
        expect(reconciler).to receive(:call)
        expect(logger).to receive(:info).with("Reconciling GIAS schools data for 2 URNs")
        expect(logger).to receive(:warn).with("The following URNs could not be reconciled: 67890")
        expect(logger).to receive(:info).with("GIAS schools data reconciliation complete!")

        Rake::Task["gias:reconcile"].invoke("12345,67890")
      end
    end
  end

  describe "gias:import_childrens_centres" do
    it "imports childrens centres with school creation enabled" do
      expect(importer).to receive(:fetch)
      expect(reconciler).to receive(:call)
      expect(logger).to receive(:info).with("GIAS schools data import complete, 2 schools to reconcile")
      expect(logger).to receive(:info).with("Childrens Centres schools data import and reconciliation complete!")

      Rake::Task["gias:import_childrens_centres"].invoke
    end
  end
end
