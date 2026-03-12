module PaymentCalculator
  class Resolver
    class ContractTypeNotSupportedError < StandardError; end
    class ContractMismatchError < StandardError; end

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :contract
    attribute :statement

    def calculators
      raise ArgumentError, "statement must be provided" if statement.blank?

      validate_contract_consistency!
      raise ArgumentError, "contract must be provided or derivable from statement" if resolved_contract.blank?

      case resolved_contract.contract_type
      when "ittecf_ectp"
        [
          FlatRate.new(
            statement:,
            flat_rate_fee_structure: resolved_contract.flat_rate_fee_structure,
            declaration_selector: ->(declarations) { declarations.mentors.with_declaration_types(%i[started completed]) },
            fee_proportions: { started: 0.5, completed: 0.5 }
          ),
          Banded.new(
            statement:,
            banded_fee_structure: resolved_contract.banded_fee_structure,
            declaration_selector: ->(declarations) { declarations.ects }
          )
        ]
      when "ecf"
        [
          Banded.new(
            statement:,
            banded_fee_structure: resolved_contract.banded_fee_structure,
            declaration_selector: ->(declarations) { declarations.all }
          )
        ]
      else
        raise ContractTypeNotSupportedError, "No payment calculator exists for contract type: #{resolved_contract.contract_type}"
      end
    end

  private

    def resolved_contract
      # Backward compatibility: some callers still pass `contract`.
      # Prefer `statement.contract`, remove `contract` arg once callers are migrated.
      @resolved_contract ||= contract || statement.contract
    end

    def validate_contract_consistency!
      return if contract.blank?
      return if contract == statement.contract

      raise ContractMismatchError, "provided contract does not match statement.contract"
    end
  end
end
