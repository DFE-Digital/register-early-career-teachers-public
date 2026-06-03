module ContractPeriods
  class Update
    attr_reader :contract_period, :author, :params

    def initialize(author:, contract_period:, params:)
      @params = params
      @contract_period = contract_period
      @author = author
    end

    def update!
      return unless contract_period.editable?

      contract_period.assign_attributes(params)
      modifications = contract_period.changes

      ActiveRecord::Base.transaction do
        contract_period.update!(params)
        record_event!(modifications)
      end

      contract_period
    end

  private

    def record_event!(modifications)
      Events::Record.record_contract_period_updated_event!(author:,
                                                           contract_period:,
                                                           modifications:)
    end
  end
end
