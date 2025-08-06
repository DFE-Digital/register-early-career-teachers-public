module Queries
  module RangeQueries
    extend ActiveSupport::Concern

    class_methods do
      def date_in_range(date, range_column: 'range')
        [%("#{table_name}"."#{range_column}" @> date(?)), date]
      end

      def containing_range(start, finish, range_column: 'range')
        [%("#{table_name}"."#{range_column}" @> daterange(?, ?)), start, finish]
      end

      def overlapping_with_range(start, finish, range_column: 'range')
        [%("#{table_name}"."#{range_column}" && daterange(?, ?)), start, finish]
      end
    end
  end
end
