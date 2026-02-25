describe "GIAS tasks" do
  let(:importer) { instance_double(GIAS::Importer) }
  let(:logger) { instance_double(Logger, info: true) }

  before do
    allow(Logger).to receive(:new).with($stdout).and_return(logger)
  end

  describe "gias:import_with_school_creation" do
    it "imports with school creation enabled" do
      allow(GIAS::Importer).to receive(:new).with(auto_create_school: true).and_return(importer)
      expect(importer).to receive(:fetch)

      Rake::Task["gias:import_with_school_creation"].invoke
    end
  end

  describe "gias:import_without_school_creation" do
    it "imports with school creation disabled" do
      allow(GIAS::Importer).to receive(:new).with(auto_create_school: false).and_return(importer)
      expect(importer).to receive(:fetch)

      Rake::Task["gias:import_without_school_creation"].invoke
    end
  end

  describe "gias:import_childrens_centres" do
    it "imports childrens centres with school creation enabled" do
      allow(GIAS::Importer).to receive(:new).with(file_source: :local, auto_create_school: true).and_return(importer)
      expect(importer).to receive(:fetch)

      Rake::Task["gias:import_childrens_centres"].invoke
    end
  end
end
