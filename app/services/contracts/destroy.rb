module Contracts
  class Destroy
    class DeletionError < StandardError; end

    attr_reader :author, :contract

    def initialize(author:, contract:)
      @author = author
      @contract = contract
    end

    def call
      ActiveRecord::Base.transaction do
        raise DeletionError, "Cannot delete a contract that has statements" if contract.statements.any?

        active_lead_provider = contract.active_lead_provider
        Events::Record.record_contract_deleted_event!(author:, contract:, active_lead_provider:)
        contract.destroy!
      end
    end
  end
end
