module Statements
  class Calculator
    attr_reader :statement

    delegate :call_off_contract_assignments, to: :statement

    def initialize(statement)
      @statement = statement
    end

    def total
      @total ||= payment_calculators.sum(&:total)
    end

  private

    def payment_calculators
      @payment_calculators ||= call_off_contract_assignments.map do |assignment|
        CallOffContracts::PaymentCalculators::Factory.create_calculator(assignment:)
      end
    end
  end
end
