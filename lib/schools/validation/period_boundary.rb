module Schools
  module Validation
    class PeriodBoundary
      attr_reader :ect_at_school_period, :full_name, :school_name, :date, :error_message

      def initialize(ect_at_school_period:, full_name:, date:, school_name: nil)
        raise ArgumentError, "full_name is required" if full_name.blank?

        @ect_at_school_period = ect_at_school_period
        @full_name = full_name
        @school_name = school_name || "your school"
        @date = date
        @error_message = compare_date_to_boundaries
      end

      def valid?
        error_message.nil?
      end

    private

      def compare_date_to_boundaries
        period = ect_at_school_period
        return build_error_message(period) if date_before_period_starts?(period)

        period = latest_started_training_period
        build_error_message(period) if date_before_period_starts?(period)
      end

      def date_before_period_starts?(period)
        return false if date.blank?
        return false unless valid_period?(period)

        date <= earliest_possible_end_date(period)
      end

      def earliest_possible_end_date(period)  
        period.started_on.next_day
      end

      def valid_period?(period)
        period&.started_on.present?
      end

      # Unstarted training periods (ie starting today or in the future) will be deleted and should not prevent a start date at a new school from being valid
      def latest_started_training_period
        ect_at_school_period
          &.training_periods
          &.started_before(Time.zone.today)
          &.latest_first
          &.first
      end

      def build_error_message(period)
        "Our records show that #{full_name} started " \
        "#{period_description(period)} at #{school_name} on " \
        "#{formatted_date(period)}."
      end

      def formatted_date(period)
        period.started_on.to_formatted_s(:govuk)
      end

      def period_description(period)
        case period
        when ECTAtSchoolPeriod then "teaching"
        when TrainingPeriod    then "their latest training"
        end
      end
    end
  end
end
