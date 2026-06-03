require Rails.root.join("db/seeds/blazer_queries/school_comms")

describe "blazer tasks" do
  describe "blazer:sync_school_comms_queries" do
    let(:logger) { instance_double(Logger, info: true) }

    before do
      allow(Logger).to receive(:new).with($stdout).and_return(logger)
    end

    it "syncs the school comms queries" do
      allow(BlazerQueries::SchoolComms).to receive(:sync!).and_return([])

      Rake::Task["blazer:sync_school_comms_queries"].invoke

      expect(BlazerQueries::SchoolComms).to have_received(:sync!)
    end
  end
end
