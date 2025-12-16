RSpec.describe LegacyDataImporter do
  include ActiveJob::TestHelper

  subject(:importer) { described_class.new }

  let(:migrator1) { class_double(Migrators::Base, model: :migrator1, dependencies: []) }
  let(:migrator2) { class_double(Migrators::Base, model: :migrator2, dependencies: [:migrator1]) }

  before do
    allow(migrator1).to receive(:record_count).and_return(10)
    allow(migrator2).to receive(:record_count).and_return(20)
    allow(Migrators::Base).to receive(:migrators).and_return [migrator1, migrator2]
  end

  describe "version filtering" do
    let(:teacher_migrator) { class_double(Migrators::Base, model: :teacher, dependencies: []) }
    let(:mentorship_period_migrator) { class_double(Migrators::Base, model: :mentorship_period, dependencies: [:teacher]) }
    let(:mentor_migrator) { class_double(Migrators::Base, model: :mentor, dependencies: []) }
    let(:ect_migrator) { class_double(Migrators::Base, model: :ect, dependencies: [:mentor]) }
    let(:other_migrator) { class_double(Migrators::Base, model: :other, dependencies: []) }

    let(:all_migrators) { [teacher_migrator, mentorship_period_migrator, mentor_migrator, ect_migrator, other_migrator] }

    before do
      allow(Migrators::Base).to receive(:migrators).and_return(all_migrators)
    end

    context "with version 1 (default)" do
      subject(:importer) { described_class.new }

      it "excludes V2 migrators (mentor and ect)" do
        migrators = importer.send(:migrators)

        expect(migrators).to include(teacher_migrator, mentorship_period_migrator, other_migrator)
        expect(migrators).not_to include(mentor_migrator, ect_migrator)
      end
    end

    context "with version 2" do
      subject(:importer) { described_class.new(version: 2) }

      it "excludes V1 migrators (teacher and mentorship_period)" do
        migrators = importer.send(:migrators)

        expect(migrators).to include(mentor_migrator, ect_migrator, other_migrator)
        expect(migrators).not_to include(teacher_migrator, mentorship_period_migrator)
      end
    end

    context "with invalid version" do
      subject(:importer) { described_class.new(version: 99) }

      it "raises an ArgumentError" do
        expect { importer.send(:migrators) }.to raise_error(ArgumentError, "Unknown migrator version: 99")
      end
    end
  end

  describe "#prepare!" do
    it "calls .prepare! on each migrator" do
      expect([migrator1, migrator2]).to all(receive(:prepare!))
      importer.prepare!
    end
  end

  describe "#migrate!" do
    let!(:data_migration) { FactoryBot.create(:data_migration, :in_progress) }

    it "queues the next runnable migrator" do
      allow(migrator1).to receive(:runnable?).and_return(false)
      allow(migrator2).to receive(:runnable?).and_return(true)

      expect(migrator1).not_to receive(:queue)
      expect(migrator2).to receive(:queue)
      importer.migrate!
    end

    context "when all migrations have finished" do
      let!(:data_migration) { FactoryBot.create(:data_migration, :completed) }

      it "initiates an async refresh of the metadata" do
        allow(Migrators::Base).to receive(:migrators).and_return([])

        expect(Metadata::Manager).to receive(:refresh_all_metadata!).with(async: true)
        importer.migrate!
      end
    end
  end

  describe "#reset!" do
    it "destroys any DataMigration records" do
      FactoryBot.create_list(:data_migration, 2)
      [migrator1, migrator2].each { |migrator| allow(migrator).to receive(:reset!) }

      expect {
        importer.reset!
      }.to change { DataMigration.count }.by(-2)
    end

    it "calls .reset! on each migrator" do
      expect([migrator1, migrator2]).to all(receive(:reset!))
      importer.reset!
    end

    it "calls .destroy_all_metadata! on the manager" do
      [migrator1, migrator2].each { allow(it).to receive(:reset!) }
      expect(Metadata::Manager).to receive(:destroy_all_metadata!)
      importer.reset!
    end
  end
end
