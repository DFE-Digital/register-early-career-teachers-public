RSpec.describe GIAS::Importer, type: :service do
  let(:importer) { described_class.new }

  let(:schools_csv_path) { Rails.root.join("spec/fixtures", "gias_schools_#{GIAS::Importer::SCHOOLS_FILENAME}") }
  let(:school_links_csv_path) { Rails.root.join("spec/fixtures", "gias_schools_#{GIAS::Importer::SCHOOL_LINKS_FILENAME}") }

  let(:gias_api_client) { instance_double(GIAS::APIClient) }

  let(:replaced_school_urn) { 20_007 }
  let(:open_school_urn) { 20_001 }
  let(:independent_school_urn) { 20_002 }
  let(:closed_school_urn) { 20_005 }
  let(:closed_before_2020_school_urn) { 20_006 }

  before do
    allow(GIAS::APIClient).to receive(:new).and_return(gias_api_client)
    allow(gias_api_client).to receive(:get_files).and_return({
      GIAS::Importer::SCHOOLS_FILENAME => instance_double(File, path: schools_csv_path),
      GIAS::Importer::SCHOOL_LINKS_FILENAME => instance_double(File, path: school_links_csv_path)
    })
  end

  describe "#fetch" do
    context "when no GIAS schools exist in the database" do
      it "calls `fetch_and_import_only`" do
        expect(importer).to receive(:fetch_and_import_only).and_call_original

        importer.fetch
      end

      it "imports eligible GIAS schools" do
        expect { importer.fetch }.to change(GIAS::School, :count).by(3)
      end

      it "imports GIAS school links for the imported schools" do
        expect { importer.fetch }.to change(GIAS::SchoolLink, :count).by(2)
      end

      it "does not call any metadata refresh handlers during the process" do
        expect(Metadata::Resolver).not_to receive(:resolve_handler)

        importer.fetch
      end

      it "calls an async refresh of all the metadata" do
        expect(Metadata::Handlers::School).to receive(:refresh_all_metadata!).with(async: true)

        importer.fetch
      end

      it "assigns correct attributes to the GIAS schools" do
        importer.fetch

        school = GIAS::School.find_by(urn: "20001")
        expect(school.name).to eq("Example School 1")
        expect(school.address_line1).to eq("Main Street Primary")
        expect(school.type_name).to eq("Children's centre")

        school = GIAS::School.find_by(urn: "20002")
        expect(school.name).to eq("Independent School")
        expect(school.address_line1).to eq("Beta School")
        expect(school.type_name).to eq("Other independent school")

        school = GIAS::School.find_by(urn: "20005")
        expect(school.name).to eq("Example Recently Closed School")
        expect(school.address_line1).to eq("Sample House")
        expect(school.type_name).to eq("Local authority nursery school")
      end

      it "returns a list of URNs for reconciliation which includes all open schools" do
        urns = importer.fetch

        expect(urns).to include(open_school_urn, independent_school_urn)
      end

      it "returns a list of URNs which includes schools that have closed after 2020" do
        urns = importer.fetch

        expect(urns).to include(closed_school_urn)
      end

      it "returns a list of URNs which excludes schools that closed before 2020" do
        urns = importer.fetch

        expect(urns).not_to include(closed_before_2020_school_urn)
      end

      it "returns a list of URNs which does not include URNs for changes to schools which are not in the database" do
        urns = importer.fetch

        expect(urns).not_to include(replaced_school_urn)
      end
    end

    context "when GIAS schools already exist in the database" do
      let!(:existing_school) { FactoryBot.create(:school, :eligible) }

      before do
        FactoryBot.create(:gias_school, urn: replaced_school_urn)
      end

      it "calls `fetch_and_update`" do
        expect(importer).to receive(:fetch_and_update).and_call_original

        importer.fetch
      end

      it "imports eligible GIAS schools" do
        expect { importer.fetch }.to change(GIAS::School, :count).by(3)
      end

      it "imports GIAS school links for the imported and existing GIAS schools" do
        expect { importer.fetch }.to change(GIAS::SchoolLink, :count).by(3)
      end

      it "assigns correct attributes to the GIAS schools" do
        importer.fetch

        school = GIAS::School.find_by(urn: "20001")
        expect(school.name).to eq("Example School 1")
        expect(school.address_line1).to eq("Main Street Primary")
        expect(school.type_name).to eq("Children's centre")

        school = GIAS::School.find_by(urn: "20002")
        expect(school.name).to eq("Independent School")
        expect(school.address_line1).to eq("Beta School")
        expect(school.type_name).to eq("Other independent school")

        school = GIAS::School.find_by(urn: "20005")
        expect(school.name).to eq("Example Recently Closed School")
        expect(school.address_line1).to eq("Sample House")
        expect(school.type_name).to eq("Local authority nursery school")
      end

      it "does not call any metadata refresh handlers during the process" do
        expect(Metadata::Resolver).not_to receive(:resolve_handler)

        importer.fetch
      end

      it "does not call a refresh of all the metadata" do
        expect(Metadata::Handlers::School).not_to receive(:refresh_all_metadata!)

        importer.fetch
      end

      it "returns a list of URNs which includes schools that have been recently opened" do
        urns = importer.fetch

        expect(urns).to include(open_school_urn)
      end

      it "returns a list of URNs which includes schools that have been recently closed" do
        urns = importer.fetch

        expect(urns).to include(closed_school_urn)
      end

      context "when an existing school and its links have not changed" do
        let!(:independent_school) do
          FactoryBot.create(:gias_school,
                            status: "open",
                            urn: independent_school_urn,
                            address_line1: "Beta School",
                            address_line2: "Oak Road",
                            address_line3: "Rivertown",
                            administrative_district_name: "Sample Borough",
                            establishment_number: nil,
                            local_authority_code: 801,
                            name: "Independent School",
                            opened_on: Date.new(2012, 6, 15),
                            postcode: "EX2 2BB",
                            primary_contact_email: "beta.hub@example.org",
                            secondary_contact_email: "info.beta@example.org",
                            section_41_approved: false,
                            type_name: "Other independent school",
                            phase_name: "Not applicable",
                            ukprn: nil,
                            eligible: false)
        end

        let!(:school_link) { FactoryBot.create(:gias_school_link, urn: independent_school_urn, link_urn: 20_003, link_type: "Other") }

        it "returns a list of URNs which excludes existing schools that have not changed" do
          urns = importer.fetch

          expect(urns).not_to include(independent_school_urn)
        end
      end

      context "when an existing school has changes" do
        let!(:independent_school) { FactoryBot.create(:gias_school, status: "proposed_to_open", urn: independent_school_urn) }

        it "returns a list of URNs which includes schools that have been recently changed" do
          urns = importer.fetch

          expect(urns).to include(independent_school_urn)
        end
      end

      it "returns a list of URNs which includes schools with new gias links" do
        urns = importer.fetch

        expect(urns).to include(replaced_school_urn)
      end

      context "when a school has an existing gias link that has not changed" do
        let!(:existing_link) { FactoryBot.create(:gias_school_link, urn: replaced_school_urn, link_urn: 20_008, link_type: GIAS::SchoolLink::SUCCESSOR) }

        it "returns a list of URNs which excludes schools with existing gias_links" do
          urns = importer.fetch

          expect(urns).not_to include(replaced_school_urn)
        end
      end

      context "when a school has an existing gias link that has changed" do
        let!(:existing_link) { FactoryBot.create(:gias_school_link, urn: replaced_school_urn, link_urn: 20_008, link_type: GIAS::SchoolLink::SUCCESSOR_SPLIT) }

        it "returns a list of URNs which includes schools with updated gias links" do
          urns = importer.fetch

          expect(urns).to include(replaced_school_urn)
        end
      end
    end
  end

  describe "eligibility change events" do
    before do
      allow(Events::Record).to receive(:record_school_eligibility_changed_event!)
    end

    context "when eligibility changes" do
      before do
        FactoryBot.create(:gias_school, :with_school, urn: open_school_urn, eligible: false)
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
        FactoryBot.create(:gias_school, :with_school, urn: open_school_urn, eligible: true, name: "Old Name")
      end

      it "does not record an event" do
        importer.send(:import_schools)

        expect(Events::Record).not_to have_received(:record_school_eligibility_changed_event!)
      end
    end
  end
end
