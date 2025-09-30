module Schools
  module Validation
    class ECTStartDate < HashDate
      DATE_MISSING_MESSAGE = "Enter the date the ECT started or will start teaching at your school"
      INVALID_FORMAT_MESSAGE = "Enter the start date using the correct format, for example, 17 09 1999"

      def initialize(date_as_hash:, current_date: nil)
        super(date_as_hash)
        @current_date = current_date || Time.zone.today
      end

      # String containing the full month name and year with century. Ex: 'January 2025'
      def formatted_date
        value_as_date.strftime(Date::DATE_FORMATS[:govuk])
      end

    private

      attr_reader :current_date

      def date_missing?
        super || date_as_hash.values_at(1, 2, 3).all?(&:nil?)
      end

      def extra_validation_error_message
        return unless earliest_permitted_date
        return unless value_as_date < earliest_permitted_date

        "Start date cannot be this far in the past. Enter a date later than #{earliest_permitted_date.to_formatted_s(:govuk)}."
      end

      def earliest_permitted_date
        ContractPeriod.earliest_permitted_start_date
      end
    end
  end
end
