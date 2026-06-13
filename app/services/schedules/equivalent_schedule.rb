module Schedules
  class EquivalentSchedule
    attr_reader :source_schedule, :target_contract_period

    def initialize(source_schedule:, target_contract_period:)
      @source_schedule = source_schedule
      @target_contract_period = target_contract_period
    end

    def schedule
      Schedule.find_by(
        identifier: source_schedule.identifier,
        contract_period: target_contract_period
      )
    end
  end
end
