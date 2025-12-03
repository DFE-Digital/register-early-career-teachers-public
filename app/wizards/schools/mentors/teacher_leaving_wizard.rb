module Schools
  module Mentors
    module TeacherLeavingWizard
      class Wizard < Mentors::Wizard
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
