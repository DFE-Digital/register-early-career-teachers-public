ALL_TRNS = (1111..9_999_999) unless defined?(ALL_TRNS)

module APISeedData
  module Helpers
    class TRNGenerator
      class << self
        def next
          next_trn = next_from_available_stack
          add_to_taken_stack(next_trn)
          sprintf("%07d", next_trn)
        end

      private

        def add_to_taken_stack(next_trn)
          taken.push(next_trn)
        end

        def next_from_available_stack
          available.pop || (raise "TRN available list exhausted")
        end

        def available
          @available.presence || reseed
        end

        def reseed
          @available = (Array.new(10_000) { rand(ALL_TRNS) }.uniq - taken)
        end

        def taken
          @taken ||= ::Teacher.where.not(trn: nil).pluck(:trn).map(&:to_i)
        end
      end
    end
  end
end
