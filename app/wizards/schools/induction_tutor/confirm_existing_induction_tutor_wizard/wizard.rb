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

        def send_confirmation_email?
          store.are_these_details_correct == false
        end
      end
    end
  end
end
