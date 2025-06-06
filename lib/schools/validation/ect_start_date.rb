module Schools
  module Validation
    class ECTStartDate < HashDate
      DATE_MISSING_MESSAGE = "Enter the date the ECT started or will start teaching at your school".freeze
      INVALID_FORMAT_MESSAGE = "Enter the start date using the correct format, for example, 17 09 1999".freeze

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
    end
  end
end
