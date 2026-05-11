module ContractPeriods
  # Service creates Schedule and Milestone records and duplicates from the previous year if they exist.
  #
  # Milestone#milestone_date acts as the deadline for declarations
  #
  class DefaultScheduleGenerator
    DECLARATION_TYPES_FOR_STANDARD = %w[
      started retained-1 retained-2 retained-3 retained-4 completed
    ].freeze

    attr_reader :contract_period

    def initialize(contract_period:)
      raise ArgumentError, "Contract period is required" if contract_period.nil?

      @contract_period = contract_period
    end

    # @return [Symbol] :created, :cloned, :already_started, :already_scheduled
    def schedule!
      return :already_started if already_started?
      return :already_scheduled if already_scheduled?

      ActiveRecord::Base.transaction do
        if cloneable?
          clone_previous_schedules_and_milestones
        else
          create_default_schedules_and_milestones
        end
      end
    end

  private

    # @return [Boolean]
    def already_scheduled?
      contract_period.schedules.any?
    end

    # @return [Boolean]
    def already_started?
      contract_period.started_on_or_before_today?
    end

    # @return [Boolean]
    def cloneable?
      previous_contract_period&.schedules&.any? { |schedule| schedule.milestones.any? }
    end

    # @return [ContractPeriod, nil]
    def previous_contract_period
      @previous_contract_period ||= ContractPeriod.find_by(year: previous_period_year)
    end

    # @return [Integer]
    def previous_period_year
      contract_period.year - 1
    end

    # @return [Integer]
    def next_period_year
      contract_period.year + 1
    end

    # @param date [Date]
    # @return [Date, nil]
    def advance_year(date)
      date&.next_year
    end

    # @return [Symbol] :created
    def create_default_schedules_and_milestones
      Schedule::STANDARD_SCHEDULE_IDENTIFIERS.each do |identifier|
        schedule = Schedule.create!(contract_period:, identifier:)

        DECLARATION_TYPES_FOR_STANDARD.each do |declaration_type|
          schedule.milestones.create!(
            declaration_type:,
            start_date: schedule_start_date(identifier),
            milestone_date: nil
          )
        end
      end
      :created
    end

    # @return [Symbol] :cloned
    def clone_previous_schedules_and_milestones
      previous_contract_period.schedules.includes(:milestones).find_each do |previous_schedule|
        next if previous_schedule.milestones.none?

        new_schedule = Schedule.create!(
          contract_period:,
          identifier: previous_schedule.identifier
        )

        previous_schedule.milestones.each do |previous_milestone|
          Milestone.create!(
            schedule: new_schedule,
            declaration_type: previous_milestone.declaration_type,
            start_date: advance_year(previous_milestone.start_date),
            milestone_date: advance_year(previous_milestone.milestone_date)
          )
        end
      end
      :cloned
    end

    # @param identifier [String] e.g. "ecf-standard-september"
    # @return [Date]
    def schedule_start_date(identifier)
      case identifier
      when /september/ then Date.new(contract_period.year, 6, 1)
      when /january/ then Date.new(next_period_year, 1, 1)
      when /april/ then Date.new(next_period_year, 4, 1)
      end
    end
  end
end
