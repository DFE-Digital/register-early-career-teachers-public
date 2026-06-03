module ContractPeriods
  class Create
    attr_reader :contract_period, :author

    def initialize(author:, params:)
      @author = author
      @contract_period = ContractPeriod.new(params.merge(enabled: true))
    end

    def create!
      ActiveRecord::Base.transaction do
        contract_period.save!
        record_event!
        seed_from_previous!
      end

      contract_period
    end

  private

    def record_event!
      Events::Record.record_contract_period_added_event!(author:, contract_period:)
    end

    def seed_from_previous!
      ContractPeriods::SeedFromPrevious.new(contract_period:).schedule!
    end
  end
end
