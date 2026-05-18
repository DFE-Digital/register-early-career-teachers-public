module ContractPeriods
  # Service creates Schedule and Milestone records and duplicates from the previous year if they exist.
  #
  # Milestone#milestone_date acts as the deadline for declarations
  #
  class SeedFromPrevious
    class AlreadyScheduledError < StandardError; end
    class ContractPeriodStartedError < StandardError; end
    class NoPreviousContractPeriodError < StandardError; end

    attr_reader :contract_period

    def initialize(contract_period:)
      raise ArgumentError, "Contract period is required" if contract_period.nil?

      @contract_period = contract_period
    end

    # @raise [AlreadyScheduledError, ContractPeriodStartedError, NoPreviousContractPeriodError]
    # @return [Symbol] :scheduled
    def schedule!
      raise AlreadyScheduledError, "The contract period already has schedules" if contract_period.schedules.any?
      raise ContractPeriodStartedError, "Contract periods cannot be scheduled after they have started" if contract_period.started_on_or_before_today?
      raise NoPreviousContractPeriodError, "No previous contract period found" if previous_contract_period.blank?

      ActiveRecord::Base.transaction do
        previous_contract_period.schedules.includes(:milestones).find_each do |previous_schedule|
          new_schedule = Schedule.create!(
            contract_period:,
            identifier: previous_schedule.identifier
          )

          previous_schedule.milestones.each do |previous_milestone|
            Milestone.create!(
              schedule: new_schedule,
              declaration_type: previous_milestone.declaration_type,
              start_date: previous_milestone.start_date&.next_year,
              milestone_date: previous_milestone.milestone_date&.next_year
            )
          end
        end
      end

      :scheduled
    end

  private

    # @return [ContractPeriod, nil]
    def previous_contract_period
      @previous_contract_period ||= ContractPeriod.find_by(year: contract_period.year - 1)
    end
  end
end
