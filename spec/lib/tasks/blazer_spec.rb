require Rails.root.join("db/seeds/blazer_queries/school_comms")
require Rails.root.join("db/seeds/blazer_queries/post_closure_school_links")

describe "blazer tasks" do
  let(:logger) { instance_double(Logger, info: true) }

  before do
    allow(Logger).to receive(:new).with($stdout).and_return(logger)
  end

  describe "blazer:sync_school_comms_queries" do
    it "syncs the school comms queries" do
      allow(BlazerQueries::SchoolComms).to receive(:sync!).and_return([])

      Rake::Task["blazer:sync_school_comms_queries"].invoke

      expect(BlazerQueries::SchoolComms).to have_received(:sync!)
    end
  end

  describe "blazer:sync_post_closure_school_link_queries" do
    it "syncs the post closure school link queries" do
      allow(BlazerQueries::PostClosureSchoolLinks).to receive(:sync!).and_return([])

      Rake::Task["blazer:sync_post_closure_school_link_queries"].invoke

      expect(BlazerQueries::PostClosureSchoolLinks).to have_received(:sync!)
    end
  end
end
