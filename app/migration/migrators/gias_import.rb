module Migrators
  class GIASImport < Migrators::Base
    class_attribute :gias_importer, instance_writer: false, default: GIAS::Importer.new

    def self.model = :gias_import

    def self.record_count = gias_importer.number_of_schools_to_import + gias_importer.number_of_school_links_to_import

    def self.records_per_worker = record_count

    def self.reset!
      self.gias_importer = GIAS::Importer.new

      if Rails.application.config.enable_migration_testing
        ::GIAS::School.connection.execute("TRUNCATE #{::GIAS::School.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      DeclarativeUpdates.skip do
        start_migration!(self.class.record_count)
        preload_caches if respond_to?(:preload_caches, true)

        gias_importer.foreach_school_row do |school_row|
          process_item(school_row) { gias_importer.parse_school_row(it) }
        end

        gias_importer.foreach_school_link_row do |school_link_row|
          process_item(school_link_row) { gias_importer.parse_school_link_row(it) }
        end

        finalise_migration!
      end
    end
  end
end
