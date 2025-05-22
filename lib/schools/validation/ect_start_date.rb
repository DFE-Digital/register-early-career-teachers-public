module Schools
  module Validation
    class ECTStartDate < HashDate
      DATE_MISSING_MESSAGE = "Enter the date the ECT started or will start teaching at your school".freeze
      INVALID_FORMAT_MESSAGE = "Enter the start date using the correct format, for example, 17 09 1999".freeze
      OUT_OF_RANGE_MESSAGE = "The start date must be from within either the current academic year or one of the last 2 academic years".freeze

      def initialize(date_as_hash:, current_date: nil)
        super(date_as_hash)
        @current_date = current_date || Time.zone.today
      end

      # String containing the full month name and year with century. Ex: 'January 2025'
      def formatted_date
        value_as_date.strftime(Date::DATE_FORMATS[:govuk])
      end

      def value_as_date
        @value_as_date ||= Time.zone.local(*date_as_hash.values_at(1, 2, 3).map(&:to_i))
      end

    private

      attr_reader :current_date

      def extra_validation_error_message
        OUT_OF_RANGE_MESSAGE if out_of_range?
      end

      # The date must be in the current academic year or within the previous two academic years.
      # i.e. if user was registering an ECT in 2024 the start date could be in any of these academic years:
      # - August 22 - July 23
      # - August 23 - July 24
      # - August 24 - July 25
      def out_of_range?
        before_august = current_date.month < 8
        start_of_current_academic_year = Time.zone.local(current_date.year - (before_august ? 1 : 0), 8, 1)
        first_allowed_date = start_of_current_academic_year.prev_year(2)
        last_allowed_date = start_of_current_academic_year.next_year(1)

        !(first_allowed_date...last_allowed_date).cover?(value_as_date)
      end

      def date_missing?
        super || date_as_hash.values_at(1, 2, 3).all?(&:nil?)
      end
    end
  end
end
