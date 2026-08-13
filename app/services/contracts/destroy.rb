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

        framework_agreement = contract.framework_agreement
        Events::Record.record_contract_deleted_event!(author:, contract:, framework_agreement:)
        contract.destroy!
      end
    end
  end
end
