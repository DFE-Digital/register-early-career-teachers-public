module Builders
  module ECT
    class TrainingPeriods
      include Builders::BuilderHelpers

      attr_reader :teacher, :training_period_data

      def initialize(teacher:, training_period_data:)
        @teacher = teacher
        @training_period_data = training_period_data
      end

      def build
        success = true
        period_date = Data.define(:started_on, :finished_on)

        training_period_data.each_with_index do |period, idx|
          next_period = training_period_data[idx + 1]

          if next_period.present? && period.end_date.present? && (period.end_date > next_period.start_date || period.end_date < period.start_date)
            period_end_date = next_period.start_date
            period_end_source_id = next_period.start_source_id
          else
            period_end_date = period.end_date
            period_end_source_id = period.end_source_id
          end

          period_dates = period_date.new(started_on: period.start_date, finished_on: period_end_date)
          school = find_school_by_urn!(period.school_urn)

          ect_at_school_period = teacher
            .ect_at_school_periods
            .where(school_id: school.id)
            .containing_period(period_dates)
            .first

          training_period = ::TrainingPeriod.find_or_initialize_by(ecf_start_induction_record_id: period.start_source_id)
          training_period.training_programme = period.training_programme
          training_period.ect_at_school_period = ect_at_school_period
          training_period.started_on = period.start_date
          training_period.finished_on = period_end_date
          training_period.ecf_end_induction_record_id = period_end_source_id

          training_period.school_partnership = if period.training_programme == "provider_led"
            find_school_partnership!(period, school)
          end

          training_period.save!
        rescue ActiveRecord::ActiveRecordError => e
          ::TeacherMigrationFailure.create!(teacher:, model: :training_period, message: e.message, migration_item_id: period.start_source_id, migration_item_type: "Migration::InductionRecord")
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
