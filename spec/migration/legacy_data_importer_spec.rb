RSpec.describe LegacyDataImporter do
  include ActiveJob::TestHelper

  subject(:importer) { described_class.new }

  let(:migrator1) { class_double(Migrators::Base) }
  let(:migrator2) { class_double(Migrators::Base) }

  before do
    allow(migrator1).to receive(:record_count).and_return(10)
    allow(migrator2).to receive(:record_count).and_return(20)
  end

  describe "#prepare!" do
    it "calls .prepare! on each migrator" do
      allow(Migrators::Base).to receive(:migrators).and_return [migrator1, migrator2]
      expect([migrator1, migrator2]).to all(receive(:prepare!))
      importer.prepare!
    end
  end

  describe "#migrate!" do
    let!(:data_migration) { FactoryBot.create(:data_migration, :in_progress) }

    it "queues the next runnable migrator" do
      allow(Migrators::Base).to receive(:migrators_in_dependency_order).and_return [migrator1, migrator2]

      allow(migrator1).to receive(:runnable?).and_return(false)
      allow(migrator2).to receive(:runnable?).and_return(true)

      expect(migrator1).not_to receive(:queue)
      expect(migrator2).to receive(:queue)
      importer.migrate!
    end

    it "does not refresh the metadata when a migration is in progress" do
      expect(Metadata::Manager).not_to receive(:refresh_all_metadata!)
      importer.migrate!
    end

    context "when all migrations have finished" do
      let!(:data_migration) { FactoryBot.create(:data_migration, :completed) }

      it "initiates an async refresh of the metadata" do
        expect(Metadata::Manager).to receive(:refresh_all_metadata!).with(async: true)
        importer.migrate!
      end
    end
  end

  describe "#reset!" do
    before do
      allow(Migrators::Base).to receive(:migrators_in_dependency_order).and_return [migrator1, migrator2]
    end

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
