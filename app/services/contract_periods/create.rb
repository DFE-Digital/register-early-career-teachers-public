module ContractPeriods
  class Create
    attr_reader :contract_period, :author

    def initialize(author:, params:)
      @author = author
      @contract_period = ContractPeriod.new(params)
    end

    def create!
      raise ActiveRecord::RecordInvalid, contract_period unless contract_period.valid?

      ActiveRecord::Base.transaction do
        contract_period.save!
        record_event! or raise ActiveRecord::Rollback
      end

      contract_period
    end

  private

    def record_event!
      return false unless contract_period.persisted?

      Events::Record.record_contract_period_added_event!(author:, contract_period:)

      true
    end
  end
end
