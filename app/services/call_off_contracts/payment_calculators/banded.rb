module CallOffContracts::PaymentCalculators
  class Banded
    attr_reader :call_off_contract, :declarations

    delegate :bands, :setup_fee, to: :call_off_contract

    def initialize(call_off_contract, declarations)
      @call_off_contract = call_off_contract
      @declarations = declarations
    end

    def total
      declarations_total = declarations.count.times.sum do |index|
        band = bands.find { |b| b.min_declarations <= index && b.max_declarations >= index }
        band.fee_per_declaration
      end

      setup_fee + declarations_total
    end
  end
end
