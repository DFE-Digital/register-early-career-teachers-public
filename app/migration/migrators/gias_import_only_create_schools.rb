# This is an alternative migrator to Migrators::GIASImport.
# It assumes the database already stores all the GIAS::School entries
# Its purpose then is to just create the counterpart School rows only.
module Migrators
  class GIASImportOnlyCreateSchools < Migrators::Base
    def self.gias_schools = ::GIAS::School

    def self.model = :gias_import

    def self.record_count = gias_schools.count

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::School.connection.execute("TRUNCATE #{::School.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.gias_schools, sort_field: :urn) do |gias_school|
        migrate_one!(gias_school:)
      end
    end

    def migrate_one!(gias_school:)
      gias_school.school.present? || gias_school.create_school!
    end
  end
end
