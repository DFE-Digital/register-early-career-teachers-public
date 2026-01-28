module Schools
  module InductionTutor
    module NewInductionTutorWizard
      class Wizard < InductionTutor::Wizard
        steps do
          [{
            edit: EditStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep
          }]
        end

        def send_confirmation_email? = true
      end
    end
  end
end
