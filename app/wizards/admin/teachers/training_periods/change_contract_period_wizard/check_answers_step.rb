module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriodWizard
        class CheckAnswersStep < Step
          CurrentActivePeriodChange = ::Admin::Teachers::TrainingPeriods::ChangeContractPeriod::CurrentActivePeriod
          FuturePeriodChange = ::Admin::Teachers::TrainingPeriods::ChangeContractPeriod::FuturePeriod

          self.expected_store_keys = %i[contract_period_year]

          def previous_step
            wizard.partnership_selection_required? ? :select_partnership : :select_contract_period
          end

          def save!
            service.change_contract_period!
            true
          rescue CurrentActivePeriodChange::UnsupportedTrainingPeriodError,
                 FuturePeriodChange::UnsupportedTrainingPeriodError
            errors.add(:base, "Training period is not eligible for contract period change")
            false
          rescue CurrentActivePeriodChange::ScheduleNotFoundError,
                 FuturePeriodChange::ScheduleNotFoundError
            errors.add(:base, "A matching schedule could not be found for the selected contract period")
            false
          rescue CurrentActivePeriodChange::ActiveLeadProviderNotFoundError,
                 FuturePeriodChange::ActiveLeadProviderNotFoundError
            errors.add(:base, "An active lead provider could not be found for the selected contract period")
            false
          end

        private

          def service
            service_class.new(
              training_period: wizard.training_period,
              contract_period: wizard.selected_contract_period,
              school_partnership: wizard.selected_school_partnership,
              author: wizard.author
            )
          end

          def service_class
            return FuturePeriodChange if wizard.training_period.started_on > Time.zone.today

            CurrentActivePeriodChange
          end
        end
      end
    end
  end
end
