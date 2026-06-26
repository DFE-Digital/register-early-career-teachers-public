module Contracts
  class Create
    attr_reader :author, :active_lead_provider, :params

    def initialize(author:, active_lead_provider:, params:)
      @author = author
      @active_lead_provider = active_lead_provider
      @params = params
    end

    def call
      contract = active_lead_provider.contracts.build(params)
  
      contract.save!
      Events::Record.record_contract_created_event!(author:, contract:)
      contract
    end
  end
end
