module CallOffContracts::PaymentCalculators
  class FlatRate
    attr_reader :call_off_contract, :declarations

    def initialize(call_off_contract, declarations)
      @call_off_contract = call_off_contract
      @declarations = declarations
    end

    def total
      declarations.count * call_off_contract.fee_per_declaration
    end
  end
end
