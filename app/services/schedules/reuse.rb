module Schedules
  module Reuse
    def contract_period
      if confirmed_training_reassignment_required?
        successor_contract_period
      elsif reuse_existing_schedule?
        existing_schedule.contract_period
      else
        contract_period_at_transition
      end
    end

    def contract_period_at_transition
      @contract_period_at_transition ||= ContractPeriod.containing_date(date_of_transition)
    end

    def date_of_transition = [period.started_on, Date.current].max

    def schedule
      existing_schedule if reuse_existing_schedule?
    end

    def reuse_existing_schedule?
      return false unless existing_schedule
      return false if contract_period_reassignment_required?

      existing_schedule.contract_period != contract_period_at_transition
    end

    def confirmed_training_reassignment_required?
      contract_period_reassignment_required? && current_or_next_training_period_confirmed?
    end

    def contract_period_reassignment
      @contract_period_reassignment ||= ContractPeriods::Reassignment.new(training_period: most_recent_provider_led_period)
    end

    def most_recent_provider_led_period
      @most_recent_provider_led_period ||= training_periods&.provider_led_training_programme&.latest_first&.first
    end

    def current_or_next_training_period_confirmed?
      current_or_next_training_period&.school_partnership.present?
    end

    def current_or_next_training_period
      @current_or_next_training_period ||= period.current_or_next_training_period
    end

    def existing_schedule
      most_recent_provider_led_period&.schedule
    end

    delegate :training_periods, to: :period
    delegate :required?, to: :contract_period_reassignment, prefix: true
    delegate :successor_contract_period, to: :contract_period_reassignment
    delegate :assigned_contract_period, to: :contract_period_reassignment
    alias_method :previous_contract_period, :assigned_contract_period
    alias_method :started_on, :date_of_transition
  end
end
