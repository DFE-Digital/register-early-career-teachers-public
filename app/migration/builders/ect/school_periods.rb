module Builders
  module ECT
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
          school_period = ::ECTAtSchoolPeriod.find_or_initialize_by(teacher:, school:, started_on: period.start_date)
          school_period.ecf_start_induction_record_id = period.start_source_id
          next_period = school_periods[idx + 1]

          school_period.created_at = created_at if idx.zero?

          if next_period.present? && period.end_date.present? && (period.end_date > next_period.start_date || period.end_date < period.start_date)
            school_period.finished_on = next_period.start_date
            school_period.ecf_end_induction_record_id = next_period.start_source_id
          else
            school_period.finished_on = period.end_date
            school_period.ecf_end_induction_record_id = period.end_source_id
          end
          school_period.save!
        rescue ActiveRecord::ActiveRecordError => e
          ::TeacherMigrationFailure.create!(teacher:, model: :ect_at_school_period, message: e.message, migration_item_id: period.start_source_id, migration_item_type: "Migration::InductionRecord")
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
