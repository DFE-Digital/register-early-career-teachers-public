RSpec.describe AppropriateBodies::Importers::RejectedTeacherImporter do
  subject(:importer) { described_class.new(data_csv:, logger: fake_logger) }

  before { allow(fake_logger).to receive(:info) }

  let(:fake_logger) { double(Logger, error: true) }

  # NB: Manipulated reject data from Sharepoint will be in the DD/MM/YYY format which
  # is not the same as the DQT data (MM/DD/YYYY)
  let(:data_csv) do
    <<~CSV
      reason,trn,dqt_id_imported,dqt_id_discarded,started_on_imported,started_on_discarded,finished_on_imported,finished_on_discarded
      cannot be imported because X,1234567,ab1,ab3,,,,31/10/2012
      cannot be imported because Y,1234567,ab1,ab2,,01/01/2022,,31/10/2012
      cannot be imported,2345678,ab1,ab2,01/01/2012,,31/10/2012,16/10/2009
    CSV
  end

  describe "#import!" do
    let(:event) { teacher.events.last }

    it "logs the created teacher and event counts" do
      expect(fake_logger).to receive(:info).with("Created 2 missing teachers and added 2 rejection events for 2 TRNs")
      importer.import!
    end

    context "when all teachers are already in the database" do
      before do
        FactoryBot.create(:teacher, trn: "1234567")
        FactoryBot.create(:teacher, trn: "2345678")
      end

      it "fails fast" do
        expect { importer.import! }.to raise_error.and not_change(Teacher, :count).and not_change(Event, :count)
      end
    end

    context "when a teacher is already in the database" do
      let!(:teacher) { FactoryBot.create(:teacher, trn: "2345678") }

      before { importer.import! }

      it "creates a rejection event for the teacher" do
        expect(event.author_type).to eq("system")
        expect(event.event_type).to eq("import_from_dqt")
        expect(event.heading).to eq("DQT data import rejected")
        expect(event.body).to eq("cannot be imported")

        expect(event.metadata).to eq("originals" => [
          { "started_on" => nil, "finished_on" => "2009-10-16", "legacy_appropriate_body_id" => "ab2" },
        ])
      end

      it "creates a teacher and event for every trn in the file" do
        expect(Teacher.count).to eq(2)
        expect(Event.where(event_type: "import_from_dqt").count).to eq(2)
      end
    end

    context "when the teacher is not in the database" do
      let(:teacher) { Teacher.find_by(trn: "1234567") }

      before { importer.import! }

      it "creates a teacher record with blank names" do
        expect(teacher).to be_present
        expect(teacher.trs_first_name).to be_nil
        expect(teacher.trs_last_name).to be_nil
      end

      it "creates a rejection event for the teacher" do
        expect(event.author_type).to eq("system")
        expect(event.event_type).to eq("import_from_dqt")
        expect(event.heading).to eq("DQT data import rejected")
        expect(event.body).to eq("cannot be imported because X")

        expect(event.metadata).to eq("originals" => [
          { "started_on" => nil, "finished_on" => "2012-10-31", "legacy_appropriate_body_id" => "ab3" },
          { "started_on" => "2022-01-01", "finished_on" => "2012-10-31", "legacy_appropriate_body_id" => "ab2" }
        ])
      end

      it "creates a teacher and event for every trn in the file" do
        expect(Teacher.count).to eq(2)
        expect(Event.where(event_type: "import_from_dqt").count).to eq(2)
      end
    end
  end
end
