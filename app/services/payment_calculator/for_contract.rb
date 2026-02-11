module PaymentCalculator
  class ForContract
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
            declaration_selector: ->(declarations) { declarations.mentors }
          )
        ]
      else
        raise ContractTypeNotSupportedError, "No payment calculator exists for contract type: #{contract.contract_type}"
      end
    end
  end
end
