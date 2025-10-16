module Schools
  module ECTs
    module ChangeNameWizard
      class Wizard < ECTs::Wizard
        steps do
          [
            {
              edit: EditStep,
              check_answers: CheckAnswersStep,
              confirmation: ConfirmationStep
            }
          ]
        end
      end
    end
  end
end
