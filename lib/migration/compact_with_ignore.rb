module Migration
  module CompactWithIgnore
    refine Hash do
      # compacts the hash then converts any values that are :ignore
      # to nil
      #
      # it's useful for test cases where we want to provide minimal arguments
      # to a factory without overriding the values it provides with nil
      #
      # { started_on: 1.week.ago, finished_on: :ignore, status: nil }.compact_with_ignore
      # => { started_on: 1.week.ago, finished_on: nil }
      def compact_with_ignore
        dup.compact_with_ignore!
      end

      # compacts the hash then destructively converts any values that are :ignore
      # to nil
      #
      # it's useful for test cases where we want to provide minimal arguments
      # to a factory without overriding the values it provides with nil
      #
      # { started_on: 1.week.ago, finished_on: :ignore, status: nil }.compact_with_ignore!
      # => { started_on: 1.week.ago, finished_on: nil }
      def compact_with_ignore!
        compact!

        return {} if empty?

        transform_values! { it == :ignore ? nil : it }
      end
    end
  end
end
