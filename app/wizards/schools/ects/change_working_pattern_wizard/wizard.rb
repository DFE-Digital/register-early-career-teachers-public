module Schools
  module ECTs
    module ChangeWorkingPatternWizard
      class Wizard < ECTs::Wizard
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
