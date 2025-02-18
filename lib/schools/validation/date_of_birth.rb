module Schools
  module Validation
    class DateOfBirth < HashDate
      DATE_MISSING_MESSAGE   = "Enter a date of birth".freeze
      INVALID_FORMAT_MESSAGE = "Enter the date of birth in the correct format, for example 12 03 1998".freeze
      TOO_OLD_MESSAGE        = "The teacher cannot be more than 100 years old".freeze
      TOO_YOUNG_MESSAGE      = "The teacher cannot be less than 18 years old".freeze

    private

      def date_too_young?
        value_as_date > 18.years.ago.to_date
      end

      def date_too_old?
        value_as_date < 100.years.ago.to_date
      end

      def extra_validation_error_message
        return TOO_OLD_MESSAGE if date_too_old?

        TOO_YOUNG_MESSAGE if date_too_young?
      end
    end
  end
end
