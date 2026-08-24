module Schools
  module ECTs
    module ChangeStartDateWizard
      class Wizard < ECTs::Wizard
        steps do
          [{
            edit: EditStep,
            cannot_use_date: CannotUseDateStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep
          }]
        end
      end
    end
  end
end
