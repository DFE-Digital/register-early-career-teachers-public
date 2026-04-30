module Schools
  module Validation
    class PeriodBoundary
      attr_reader :ect_at_school_period, :date, :error_message

      def initialize(ect_at_school_period:, date:)
        @ect_at_school_period = ect_at_school_period
        @date = date
      end

      def valid?
        invalid_period.nil?
      end

      def invalid_period
        @invalid_period ||= validate_periods
      end

    private

      def validate_periods
        return if date.blank?
        return unless ect_at_school_period

        period = ect_at_school_period
        return period if date_before_period_starts?(period)

        period = latest_started_training_period
        period if date_before_period_starts?(period)
      end

      def date_before_period_starts?(period)
        return false if period&.started_on.blank?

        date <= earliest_possible_end_date(period)
      end

      def earliest_possible_end_date(period)
        period.started_on.next_day
      end

      # Unstarted training periods (ie starting in the future) will be deleted and should not prevent a start date at a new school from being valid
      def latest_started_training_period
        ect_at_school_period
          .training_periods
          .started_on_or_before(Time.zone.today)
          .latest_first
          .first
      end
    end
  end
end
