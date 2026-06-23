module Contracts
  class Destroy
    class DeletionError < StandardError; end

    attr_reader :author, :contract

    def initialize(author:, contract:)
      @author = author
      @contract = contract
    end

    def call
      raise DeletionError, "Cannot delete a contract that has statements" if contract.statements.any?

      active_lead_provider = contract.active_lead_provider
      contract.destroy!
      Events::Record.record_contract_deleted_event!(author:, active_lead_provider:)
    end
  end
end
