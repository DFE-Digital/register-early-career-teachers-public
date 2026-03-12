module Schools
  module ECTs
    module ChangeTrainingProgrammeWizard
      class Wizard < ECTs::Wizard
        steps do
          [{
            edit: EditStep,
            lead_provider: LeadProviderStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep
          }]
        end

        def effective_training_period
          ect_at_school_period.current_or_next_training_period ||
            ect_at_school_period.latest_training_period
        end
      end
    end
  end
end
