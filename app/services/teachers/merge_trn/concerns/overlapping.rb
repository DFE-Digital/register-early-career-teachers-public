module Teachers
  class MergeTRN
    module Concerns
      module Overlapping
        extend ActiveSupport::Concern

        include Periods::Overlapping

        def initialize(periods:)
          @periods = periods
        end

        def find
          return [] if periods.empty?
          raise ArgumentError, "Periods must be of the same type" if wrong_period_type?

          super
        end

      private

        attr_reader :periods

        def period_type
          raise NotImplementedError, "Subclasses must define the period_type"
        end

        def wrong_period_type?
          periods.map(&:class).any? { |type| type.to_s.underscore.to_sym != period_type }
        end
      end
    end
  end
end
