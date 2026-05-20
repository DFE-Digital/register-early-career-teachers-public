module ContractPeriods
  class Create
    attr_reader :contract_period, :author

    def initialize(author:, params:)
      @author = author
      @contract_period = ContractPeriod.new(params.merge(enabled: true))
    end

    def create!
      return false unless contract_period.valid?

      ActiveRecord::Base.transaction do
        contract_period.save!
        record_event!
        add_schedules_and_milestones!
      end

      contract_period
    end

  private

    def record_event!
      Events::Record.record_contract_period_added_event!(author:, contract_period:)
    end

    def add_schedules_and_milestones!
      ContractPeriods::SeedFromPrevious.new(contract_period:).schedule!
    end
  end
end
