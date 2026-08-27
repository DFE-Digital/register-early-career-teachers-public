RSpec.describe AppropriateBodies::Importers::RejectedTeacherImporter do
  subject(:importer) do
    described_class.new(data_csv:, logger: fake_logger)
  end

  let(:fake_logger) { double(Logger, error: true) }
  let(:data_csv) do
    <<~CSV
      reason,trn,dqt_id_imported,dqt_id_discarded,started_on_imported,started_on_discarded,finished_on_imported,finished_on_discarded
      cannot be imported,1234567,ab1,ab3,,,,10/31/2012
      cannot be imported,1234567,ab1,ab2,,01/01/2022,,10/31/2012
      cannot be imported,2345678,ab1,ab2,01/01/2012,,10/31/2012,
    CSV
  end

  let(:teacher) { Teacher.find_by(trn: "1234567") }

  describe "#import!" do
    before do
      allow(fake_logger).to receive(:info) # suppress logging during tests
    end

    context "when the teacher is not in the service" do
      it "creates a teacher record with blank names" do
        importer.import!

        expect(teacher).to be_present
        expect(teacher.trs_first_name).to be_nil
        expect(teacher.trs_last_name).to be_nil
      end

      it "creates a rejection event for the teacher" do
        importer.import!

        event = teacher.events.last

        expect(event.author_type).to eq("system")
        expect(event.event_type).to eq("import_from_dqt")
        expect(event.heading).to eq("DQT data import rejected")
        expect(event.body).to eq("cannot be imported")

        expect(event.metadata).to eq("originals" => [
          { "started_on" => nil, "finished_on" => "10/31/2012", "legacy_appropriate_body_id" => "ab3" },
          { "started_on" => "01/01/2022", "finished_on" => "10/31/2012", "legacy_appropriate_body_id" => "ab2" }
        ])
      end

      it "creates a teacher and event for every trn in the file" do
        expect { importer.import! }.to change(Teacher, :count).by(2)
        expect(Event.where(event_type: "import_from_dqt").count).to eq(2)
      end
    end

    context "when the teacher is already in the service" do
      let(:data_csv) do
        <<~CSV
          reason,trn,dqt_id_imported,dqt_id_discarded,started_on_imported,started_on_discarded,finished_on_imported,finished_on_discarded
          cannot be imported because started_on is nil,1234567,ab1,,,01/01/2012,,10/31/2012
        CSV
      end

      before { FactoryBot.create(:teacher, trn: "1234567") }

      it "does not create a duplicate teacher or event" do
        expect { importer.import! }.not_to change(Teacher, :count)
        expect(teacher.events).to be_empty
      end
    end

    context "when a trn appears in multiple rejected rows" do
      let(:data_csv) do
        <<~CSV
          reason,trn,dqt_id_imported,dqt_id_discarded,started_on_imported,started_on_discarded,finished_on_imported,finished_on_discarded
          cannot be imported because started_on is nil,1234567,ab1,,,01/01/2012,,10/31/2012
          cannot be imported because finished_on is nil,1234567,ab1,,01/01/2012,,10/31/2012,
        CSV
      end

      it "creates a single teacher with one event using the first reason" do
        importer.import!

        expect(Teacher.count).to eq(1)
        expect(teacher.events.count).to eq(1)
        expect(teacher.events.first.body).to eq("cannot be imported because started_on is nil")
      end
    end
  end
end
