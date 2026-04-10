module ECTAtSchoolPeriods
  class ChangeLeadProvider
    class SchoolLedTrainingProgrammeError < StandardError; end

    include Teachers::LeadProviderChanger

    def call
      raise SchoolLedTrainingProgrammeError if training_period&.school_led_training_programme?

      super
    end

  private

    def ect_at_school_period
      period
    end

    def finish_training_period!
      TrainingPeriods::Finish.ect_training(
        training_period:,
        ect_at_school_period:,
        finished_on: Date.current,
        author:
      ).finish!
    end

    def track_payments_frozen_year!
      return unless contract_period_reassignment_required? && training_period_confirmed?

      teacher.update!(ect_payments_frozen_year: previous_contract_period.year)
    end

    def previous_contract_period = contract_period_reassignment.assigned_contract_period

    def contract_period_reassignment_required?
      @contract_period_reassignment_required ||= contract_period_reassignment.required?
    end

    def contract_period_at_transition
      @contract_period_at_transition ||= if contract_period_reassignment_required? && training_period_confirmed?
                                           successor_contract_period
                                         else
                                           super
                                         end
    end

    def contract_period_reassignment
      @contract_period_reassignment ||= ContractPeriods::Reassignment.new(training_period: last_provider_led_training_period)
    end

    delegate :successor_contract_period, to: :contract_period_reassignment
  end
end
