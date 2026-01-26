module CallOffContracts::PaymentCalculators
  class Factory
    def self.create_calculator(assignment:)
      call_off_contract = assignment.call_off_contract
      declaration_resolver = CallOffContracts::DeclarationResolvers::Factory.create_resolver(assignment:)
      declarations = declaration_resolver.resolve_declarations

      case call_off_contract
      when CallOffContract::Banded
        Banded.new(call_off_contract, declarations)
      when CallOffContract::FlatRate
        Banded.new(call_off_contract, declarations)
      else
        raise "Unknown call off contract type: #{call_off_contract.class.name}"
      end
    end
  end
end
