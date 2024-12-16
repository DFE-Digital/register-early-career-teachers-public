module Schools
  module Validation
    class ECTStartDate
      attr_reader :format_error

      # ect_start_date_as_hash: { 1 => year, 2 => month, 3 => day }
      def initialize(ect_start_date_as_hash:, current_date: nil)
        @ect_start_date_as_hash = ect_start_date_as_hash
        @current_date = current_date || Time.zone.today
        @format_error = nil
      end

      def valid?
        validate
        format_error.nil?
      end

      def formatted_start_date
        start_date.strftime("%B %Y")
      end

    private

      attr_reader :ect_start_date_as_hash, :current_date

      def validate
        return @format_error = "Enter the date the ECT started or will start teaching at your school" if date_missing?
        return @format_error = "Enter the start date using the correct format, for example 03 1998" if invalid_date?
        return @format_error = "The start date must be from within either the current academic year or one of the last 2 academic years" if start_date_out_of_range?

        true
      end

      # Start date must be in the current academic year or within the previous two academic years.
      # i.e. if user was registering an ECT in 2024 the start date could be in any of these academic years:
      # - August 22 - July 23
      # - August 23 - July 24
      # - August 24 - July 25
      def start_date_out_of_range?
        before_august = current_date.month < 8
        start_of_current_academic_year = Time.zone.local(current_date.year - (before_august ? 1 : 0), 8, 1)
        first_allowed_date = start_of_current_academic_year.prev_year(2)
        last_allowed_date = start_of_current_academic_year.next_year(1)

        !(first_allowed_date...last_allowed_date).cover?(start_date)
      end

      def date_missing?
        return true if ect_start_date_as_hash.nil?

        ect_start_date_as_hash
          .values_at(1, 2)
          .all?(&:nil?)
      end

      def invalid_date?
        start_date
        false
      rescue StandardError
        true
      end

      def start_date
        month = ect_start_date_as_hash[2].to_i
        year = ect_start_date_as_hash[1].to_i

        Time.zone.local(year, month)
      end
    end
  end
end
