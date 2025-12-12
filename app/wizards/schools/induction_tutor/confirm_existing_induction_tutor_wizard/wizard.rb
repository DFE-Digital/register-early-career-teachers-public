module Schools
  module InductionTutor
    module ConfirmExistingInductionTutorWizard
      class Wizard < InductionTutor::Wizard
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
