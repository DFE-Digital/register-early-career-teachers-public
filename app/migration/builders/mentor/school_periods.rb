module Builders
  module Mentor
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
          school_period = ::MentorAtSchoolPeriod.find_or_initialize_by(teacher:, school:, started_on: period.start_date)
          school_period.finished_on = period.end_date
          school_period.ecf_start_induction_record_id = period.start_source_id
          school_period.ecf_end_induction_record_id = period.end_source_id
          school_period.save!
        rescue ActiveRecord::ActiveRecordError => e
          ::TeacherMigrationFailure.create!(teacher:, model: :mentor_at_school_period, message: e.message, migration_item_id: period.start_source_id, migration_item_type: "Migration::InductionRecord")
          success = false
        end

        success
      end
    end
  end
end
