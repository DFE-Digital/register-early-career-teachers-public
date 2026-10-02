module Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Operations
  class ApplyContractPeriodChange
    CurrentActivePeriodChange = ::Admin::Teachers::TrainingPeriods::ChangeContractPeriod::CurrentActivePeriod
    FuturePeriodChange = ::Admin::Teachers::TrainingPeriods::ChangeContractPeriod::FuturePeriod

    def initialize(repository:, step:)
      @repository = repository
      @step = step
    end

    def execute
      service.change_contract_period!

      { success: true }
    rescue CurrentActivePeriodChange::UnsupportedTrainingPeriodError,
           FuturePeriodChange::UnsupportedTrainingPeriodError
      failure("Training period is not eligible for contract period change")
    rescue CurrentActivePeriodChange::ScheduleNotFoundError,
           FuturePeriodChange::ScheduleNotFoundError
      failure("A matching schedule could not be found for the selected contract period")
    rescue CurrentActivePeriodChange::FrameworkAgreementNotFoundError,
           FuturePeriodChange::FrameworkAgreementNotFoundError
      failure("A lead provider framework agreement could not be found for the selected contract period")
    end

  private

    attr_reader :repository, :step

    delegate :wizard, to: :step, private: true
    delegate :state_store, :author, to: :wizard, private: true
    delegate :training_period, to: :state_store, private: true

    def service
      service_class.new(
        training_period:,
        contract_period: state_store.selected_contract_period,
        school_partnership: state_store.selected_school_partnership,
        author:
      )
    end

    def service_class
      if training_period.started_on > Time.zone.today
        FuturePeriodChange
      else
        CurrentActivePeriodChange
      end
    end

    def failure(message)
      step.errors.add(:base, message)

      { success: false, errors: step.errors }
    end
  end
end
