module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriodWizard
        class CheckAnswersStep < Step
          CurrentActivePeriodChange = ::Admin::Teachers::TrainingPeriods::ChangeContractPeriod::CurrentActivePeriod

          self.expected_store_keys = %i[contract_period_year school_partnership_id]

          def previous_step = :select_partnership

          def save!
            service.change_contract_period!
            true
          rescue CurrentActivePeriodChange::UnsupportedTrainingPeriodError
            errors.add(:base, "Training period is not eligible for contract period change")
            false
          rescue CurrentActivePeriodChange::ScheduleNotFoundError
            errors.add(:base, "A matching schedule could not be found for the selected contract period")
            false
          end

        private

          def service
            CurrentActivePeriodChange.new(
              training_period: wizard.training_period,
              contract_period: wizard.selected_contract_period,
              school_partnership: wizard.selected_school_partnership,
              author: wizard.author
            )
          end
        end
      end
    end
  end
end
