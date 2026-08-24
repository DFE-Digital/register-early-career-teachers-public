module Contracts
  class Create
    attr_reader :author, :framework_agreement, :params

    def initialize(author:, framework_agreement:, params:)
      @author = author
      @framework_agreement = framework_agreement
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        contract = framework_agreement.contracts.build(params)
        contract.save!
        Events::Record.record_contract_created_event!(author:, contract:)
        contract
      end
    end
  end
end
