module Queries
  module RangeQueries
    extend ActiveSupport::Concern

    class_methods do
      def date_in_range_inclusive_start_exclusive_end(date, range_column: "range")
        [%("#{table_name}"."#{range_column}" @> date(?)), date]
      end

      def date_in_range_inclusive_start_inclusive_end(date, range_column: "range")
        [%(
          daterange(
            lower("#{table_name}"."#{range_column}"),
            upper("#{table_name}"."#{range_column}"),
            '[]'
          ) @> date(?)
        ).squish,
         date]
      end

      alias_method :date_in_range, :date_in_range_inclusive_start_exclusive_end

      def containing_range(start, finish, range_column: "range")
        [%("#{table_name}"."#{range_column}" @> daterange(?, ?)), start, finish]
      end

      def overlapping_with_range(start, finish, range_column: "range")
        [%("#{table_name}"."#{range_column}" && daterange(?, ?)), start, finish]
      end
    end
  end
end
