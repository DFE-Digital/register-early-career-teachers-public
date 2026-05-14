module ContractPeriods
  # Service creates Schedule and Milestone records and duplicates from the previous year if they exist.
  #
  # Milestone#milestone_date acts as the deadline for declarations
  #
  class SeedFromPrevious
    DECLARATION_TYPES_FOR_STANDARD = %w[
      started retained-1 retained-2 retained-3 retained-4 completed
    ].freeze

    class AlreadyScheduledError < StandardError; end
    class ContractPeriodStartedError < StandardError; end
    class UnknownIdentifierError < StandardError; end

    attr_reader :contract_period

    def initialize(contract_period:)
      raise ArgumentError, "Contract period is required" if contract_period.nil?

      @contract_period = contract_period
    end

    # @raise [AlreadyScheduledError, ContractPeriodStartedError]
    # @return [Symbol] :no_previous_contract_period, :scheduled
    def schedule!
      raise AlreadyScheduledError, "The contract period already has schedules" if contract_period.schedules.any?
      raise ContractPeriodStartedError, "Contract periods cannot be scheduled after they have started" if contract_period.started_on_or_before_today?

      return :no_previous_contract_period if previous_contract_period.blank?

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

    # @return [Integer]
    def next_period_year
      contract_period.year + 1
    end

    # @param identifier [String] e.g. "ecf-standard-september"
    # @raise [UnknownIdentifierError]
    # @return [Date]
    def schedule_start_date(identifier)
      case identifier
      when /september/ then Date.new(contract_period.year, 6, 1)
      when /january/ then Date.new(next_period_year, 1, 1)
      when /april/ then Date.new(next_period_year, 4, 1)
      else raise UnknownIdentifierError, "Unknown schedule identifier: #{identifier}"
      end
    end
  end
end
