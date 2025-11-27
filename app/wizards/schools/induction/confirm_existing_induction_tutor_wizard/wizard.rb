module Schools
  module Induction
    module ConfirmExistingInductionTutorWizard
      class Wizard < Schools::Induction::Wizard
        steps do
          [{
            edit: EditStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep
          }]
        end
      end
    end
  end
end
