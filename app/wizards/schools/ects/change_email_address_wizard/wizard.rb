module Schools
  module ECTs
    module ChangeEmailAddressWizard
      class Wizard < ApplicationWizard
        attr_accessor :store, :ect_at_school_period, :author

        steps do
          [{
            edit: EditStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep
          }]
        end

        def self.step?(step_name) = steps.first.key?(step_name)

        delegate :save!, to: :current_step
        delegate :reset, to: :store

        def default_path_arguments = { ect_id: ect_at_school_period.id }

        def teacher_full_name
          Teachers::Name.new(ect_at_school_period.teacher).full_name
        end
      end
    end
  end
end
