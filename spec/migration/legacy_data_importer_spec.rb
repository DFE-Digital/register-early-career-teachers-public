RSpec.describe LegacyDataImporter, :with_metadata do
  include ActiveJob::TestHelper

  subject(:importer) { described_class.new }

  let(:migrator1) { class_double(Migrators::Base, model: :migrator1, dependencies: []) }
  let(:migrator2) { class_double(Migrators::Base, model: :migrator2, dependencies: [:migrator1]) }

  before do
    allow(migrator1).to receive(:record_count).and_return(10)
    allow(migrator2).to receive(:record_count).and_return(20)
    allow(Migrators::Base).to receive(:migrators).and_return [migrator1, migrator2]
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

        expect(Metadata::Manager).to receive(:refresh_all_metadata!).with(async: true, excluding_handlers: [Metadata::Handlers::School])
        importer.migrate!
      end

      context "when we have to create school contract period metadata" do
        let!(:migration_school_1) { FactoryBot.create(:ecf_migration_school) }
        let!(:migration_school_cohort_1) { FactoryBot.create(:migration_school_cohort, school: migration_school_1) }
        let!(:migrated_school_1) { FactoryBot.create(:school, urn: migration_school_1.urn) }
        let!(:migration_school_2) { FactoryBot.create(:ecf_migration_school) }
        let!(:migration_school_cohort_2) { FactoryBot.create(:migration_school_cohort, school: migration_school_2) }
        let!(:migrated_school_2) { FactoryBot.create(:school, urn: migration_school_2.urn) }

        around do |example|
          Metadata::SchoolContractPeriod.bypass_update_restrictions { example.run }
        end

        before do
          allow(Migrators::Base).to receive(:migrators).and_return([])
          allow(Metadata::Manager).to receive(:refresh_all_metadata!).with(async: true, excluding_handlers: [Metadata::Handlers::School])
        end

        it "calls .refresh_metadata! on the `Metadata::Manager` for each school" do
          manager = instance_double(Metadata::Manager, refresh_metadata!: nil)
          allow(Metadata::Manager).to receive(:new) { manager }

          importer.migrate!

          expect(manager).to have_received(:refresh_metadata!).with(migrated_school_1)
          expect(manager).to have_received(:refresh_metadata!).with(migrated_school_2)
        end

        it "creates the correct school contract period metadata" do
          importer.migrate!

          ecf_schools = [migration_school_1, migration_school_2]
          schools_by_urn = School.where(urn: ecf_schools.map(&:urn)).index_by(&:urn)
          metadata_by_school_and_year = Metadata::SchoolContractPeriod.where(school: schools_by_urn.values).index_by do |metadata|
            [metadata.school_id, metadata.contract_period_year]
          end

          ecf_schools.each do |ecf_school|
            school = schools_by_urn[ecf_school.urn.to_i]
            ecf_school.school_cohorts.each do |school_cohort|
              metadata = metadata_by_school_and_year[[school.id, school_cohort.cohort.start_year]]
              expect(metadata.contract_period_year).to eq(school_cohort.cohort.start_year)
              expect(metadata.api_updated_at).to eq([ecf_school.updated_at, school_cohort.updated_at].max)
              expect(metadata.school).to eq(school)
            end
          end
        end
      end
    end
  end

  describe "#reset!" do
    it "destroys any DataMigration records" do
      FactoryBot.create_list(:data_migration, 2)
      [migrator1, migrator2].each { |migrator| allow(migrator).to receive(:reset!) }

      expect {
        importer.reset!
      }.to change(DataMigration, :count).by(-2)
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
