module Schools
  module ECTs
    module ChangeEmailAddressWizard
      class Wizard < ECTs::Wizard
        steps do
          [{
            edit: EditStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep
          }]
        end

        delegate :save!, to: :current_step
        delegate :reset, to: :store
      end
    end
  end
end
