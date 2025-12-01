module Schools
  module Validation
    class LeavingDate < HashDate
      DATE_MISSING_MESSAGE = "Enter the date the teacher left or will be leaving your school"
      FUTURE_LIMIT_MESSAGE = "Enter a date no further than 4 months from today"

    private

      def extra_validation_error_message
        return unless value_as_date

        max_date = Time.zone.today + 4.months
        FUTURE_LIMIT_MESSAGE if value_as_date > max_date
      end
    end
  end
end
