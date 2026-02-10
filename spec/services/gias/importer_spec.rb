RSpec.describe GIAS::Importer, type: :service do
  let(:importer) { described_class.new }

  let(:schools_csv_path) { Rails.root.join("spec/fixtures", "gias_schools_#{GIAS::Importer::SCHOOLS_FILENAME}") }
  let(:school_links_csv_path) { Rails.root.join("spec/fixtures", "gias_schools_#{GIAS::Importer::SCHOOL_LINKS_FILENAME}") }

  let(:gias_api_client) { instance_double(GIAS::APIClient) }

  before do
    allow(GIAS::APIClient).to receive(:new).and_return(gias_api_client)
    allow(gias_api_client).to receive(:get_files).and_return({
      GIAS::Importer::SCHOOLS_FILENAME => instance_double(File, path: schools_csv_path),
      GIAS::Importer::SCHOOL_LINKS_FILENAME => instance_double(File, path: school_links_csv_path)
    })
  end

  describe "#fetch" do
    context "when no schools exist in the database" do
      it "calls `fetch_and_import_only`" do
        expect(importer).to receive(:fetch_and_import_only).and_call_original

        importer.fetch
      end
    end

    context "when schools already exist in the database" do
      before { FactoryBot.create(:school, :eligible) }

      it "calls `fetch_and_update`" do
        expect(importer).to receive(:fetch_and_update).and_call_original

        importer.fetch
      end
    end

    it "does not call any metadata refresh handlers during the process" do
      expect(Metadata::Resolver).not_to receive(:resolve_handler)

      importer.fetch
    end

    it "calls an async refresh of the metadata" do
      expect(Metadata::Handlers::School).to receive(:refresh_all_metadata!).with(async: true)

      importer.fetch
    end
  end

  describe "#import_schools" do
    it "creates only schools that are eligible for import from the CSV data" do
      expect { importer.send(:import_schools) }.to change(School, :count).by(3)
    end

    it "assigns correct attributes to the schools" do
      importer.send(:import_schools)

      school = School.find_by(urn: "20001")
      expect(school.name).to eq("Example School 1")
      expect(school.address_line1).to eq("Main Street Primary")
      expect(school.type_name).to eq("Children's centre")

      school = School.find_by(urn: "20002")
      expect(school.name).to eq("Independent School")
      expect(school.address_line1).to eq("Beta School")
      expect(school.type_name).to eq("Other independent school")

      school = School.find_by(urn: "20005")
      expect(school.name).to eq("Example Recently Closed School")
      expect(school.address_line1).to eq("Sample House")
      expect(school.type_name).to eq("Local authority nursery school")
    end
  end

  describe "#import_school_links" do
    context "when linked schools exist" do
      before do
        # Ensure schools exist for linking
        importer.send(:import_schools)
      end

      it "creates only eligible schools links from the CSV data" do
        expect { importer.send(:import_school_links) }.to change(GIAS::SchoolLink, :count).by(2)
      end
    end

    context "when linked schools do not exist" do
      it "does not create any school link" do
        expect { importer.send(:import_school_links) }.not_to change(GIAS::SchoolLink, :count)
      end
    end
  end

  describe "eligibility change events" do
    before do
      allow(Events::Record).to receive(:record_school_eligibility_changed_event!)
    end

    context "when eligibility changes" do
      before do
        FactoryBot.create(:gias_school, :with_school, urn: 20001, eligible: false)
      end

      it "records an event with the raw modifications" do
        importer.send(:import_schools)

        expect(Events::Record).to have_received(:record_school_eligibility_changed_event!).with(
          hash_including(
            author: instance_of(Events::SystemAuthor),
            school_name: "Example School 1",
            eligibility: true,
            modifications: hash_including("eligible" => [false, true])
          )
        )
      end
    end

    context "when eligibility does not change" do
      before do
        FactoryBot.create(:gias_school, :with_school, urn: 20001, eligible: true, name: "Old Name")
      end

      it "does not record an event" do
        importer.send(:import_schools)

        expect(Events::Record).not_to have_received(:record_school_eligibility_changed_event!)
      end
    end
  end
end
