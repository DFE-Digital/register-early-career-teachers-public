module PaymentCalculator
  class Resolver
    class ContractTypeNotSupportedError < StandardError; end

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :contract
    attribute :statement

    def calculators
      case contract.contract_type
      when "ittecf_ectp"
        [
          FlatRate.new(
            statement:,
            flat_rate_fee_structure: contract.flat_rate_fee_structure,
            declaration_selector: ->(declarations) { declarations.mentors.with_declaration_types(%i[started completed]) },
            fee_proportions: { started: 0.5, completed: 0.5 }
          ),
          Banded.new(
            statement:,
            banded_fee_structure: contract.banded_fee_structure,
            declaration_selector: ->(declarations) { declarations.ects }
          )
        ]
      when "ecf"
        [
          Banded.new(
            statement:,
            banded_fee_structure: contract.banded_fee_structure,
            declaration_selector: ->(declarations) { declarations.all }
          )
        ]
      else
        raise ContractTypeNotSupportedError, "No payment calculator exists for contract type: #{contract.contract_type}"
      end
    end
  end
end
