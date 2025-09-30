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
      end
    end
  end
end
