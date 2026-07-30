module Schools
  module Mentors
    module ChangeNameWizard
      class Wizard < Mentors::Wizard
        steps do
          [
            {
              edit: EditStep,
              confirm_name_change: ConfirmNameChangeStep,
              check_answers: CheckAnswersStep,
              confirmation: ConfirmationStep,
            }
          ]
        end
      end
    end
  end
end
