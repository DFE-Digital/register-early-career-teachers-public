module Schools
  module ECTs
    module ChangeNameWizard
      class Wizard < ECTs::Wizard
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
