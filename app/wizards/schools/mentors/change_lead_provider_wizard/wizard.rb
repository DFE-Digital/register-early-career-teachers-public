module Schools
  module Mentors
    module ChangeLeadProviderWizard
      class Wizard < Mentors::Wizard
        steps do
          [{
            edit: EditStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep,
          }]
        end
      end
    end
  end
end
