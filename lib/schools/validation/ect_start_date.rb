module Schools
  module Validation
    class ECTStartDate
      attr_reader :format_error

      # Initializer expects a Hash with the format { 1 => year, 2 => month, 3 => day }

      def initialize(ect_start_date_as_hash)
        @ect_start_date_as_hash = ect_start_date_as_hash
        @format_error = nil
      end

      def valid?
        validate
        format_error.nil?
      end

    private

      attr_reader :ect_start_date_as_hash

      def validate
        return @format_error = "Start date cannot be blank" if date_missing?
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
        current_date = Time.zone.today
        current_year_start = Date.new(current_date.year, 8, 1)
        previous_years_start = [
          current_year_start.prev_year,
          current_year_start.prev_year(2)
        ]

        valid_ranges = [
          (previous_years_start[1]...previous_years_start[0]),
          (previous_years_start[0]...current_year_start),
          (current_year_start...(current_year_start + 1.year))
        ]

        valid_ranges.none? { |range| range.cover?(start_date) }
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
      rescue ArgumentError
        true
      end

      def start_date
        month = ect_start_date_as_hash[2].to_i
        year = ect_start_date_as_hash[1].to_i

        @start_date ||= Date.new(year, month)
      end
    end
  end
end
