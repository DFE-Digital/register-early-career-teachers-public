module Builders
  module Mentor
    class SchoolPeriods
      attr_reader :teacher, :school_periods, :created_at

      def initialize(teacher:, school_periods:, created_at:)
        @teacher = teacher
        @school_periods = school_periods
        @created_at = created_at
      end

      def build
        success = true
        school_periods.each_with_index do |period, idx|
          school = find_school_by_urn!(period.urn)
          school_period = ::MentorAtSchoolPeriod.find_or_initialize_by(teacher:, school:, started_on: period.start_date)
          school_period.finished_on = period.end_date
          school_period.ecf_start_induction_record_id = period.start_source_id
          school_period.ecf_end_induction_record_id = period.end_source_id
          school_period.created_at = created_at if idx.zero?
          school_period.save!
        rescue ActiveRecord::ActiveRecordError => e
          ::TeacherMigrationFailure.create!(teacher:, model: :mentor_at_school_period, message: e.message, migration_item_id: period.start_source_id, migration_item_type: "Migration::InductionRecord")
          success = false
        end

        success
      end

      private

      def find_school_by_urn!(urn)
        school = CacheManager.instance.find_school_by_urn(urn)
        raise(ActiveRecord::RecordNotFound, "Couldn't find School with URN: #{urn}") unless school

        school
      end
    end
  end
end
