module PaymentCalculator
  class Collection
    class MissingCalculatorError < StandardError; end

    include Enumerable

    def self.for(statement)
      new(Resolver.new(statement:).calculators)
    end

    def initialize(calculators)
      @calculators = calculators
    end

    def each(&) = ordered.each(&)

    def banded_calculator = find(&:banded?) || missing!("banded")
    def flat_rate_calculator = find(&:flat_rate?) || missing!("flat-rate")

  private

    def missing!(type)
      raise MissingCalculatorError, "Expected a #{type} payment calculator but none was present"
    end

    def ordered
      @ordered ||= @calculators.sort_by { it.banded? ? 0 : 1 }
    end
  end
end
