module Contracts
  class Update
    attr_reader :author, :contract, :params

    def initialize(author:, contract:, params:)
      @author = author
      @contract = contract
      @params = params
    end

    def call
      contract.assign_attributes(params)
      modifications = contract.changes
      contract.save!
      Events::Record.record_contract_updated_event!(author:, contract:, modifications:)
      contract
    end
  end
end
