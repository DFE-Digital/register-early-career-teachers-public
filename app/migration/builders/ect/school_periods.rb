module Builders
  module ECT
    class SchoolPeriods
      attr_reader :teacher, :school_periods

      def initialize(teacher:, school_periods:)
        @teacher = teacher
        @school_periods = school_periods
      end

      def build
        success = true
        school_periods.each do |period|
          school = School.find_by!(urn: period.urn)
          ::ECTAtSchoolPeriod.create!(teacher:,
                                      school:,
                                      started_on: period.start_date,
                                      finished_on: period.end_date,
                                      legacy_start_id: period.start_source_id,
                                      legacy_end_id: period.end_source_id)
        rescue ActiveRecord::ActiveRecordError => e
          ::TeacherMigrationError.create!(teacher:, message: e.message, migration_item_id: period.start_source_id, migration_item_type: "Migration::InductionRecord")
          success = false
        end

        success
      end
    end
  end
end
