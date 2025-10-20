module Schools
  module ECTs
    module ChangeLeadProviderWizard
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
