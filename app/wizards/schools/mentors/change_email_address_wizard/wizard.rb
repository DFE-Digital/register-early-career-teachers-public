module Schools
  module Mentors
    module ChangeEmailAddressWizard
      class Wizard < ApplicationWizard
        attr_accessor :store, :mentor

        steps do
          [{
            edit: EditStep,
            check_answer: CheckAnswerStep,
            confirmation: ConfirmationStep
          }]
        end

        def self.step?(step_name) = steps.first.key?(step_name)

        delegate :save!, to: :current_step
        delegate :reset!, to: :store

        def default_path_arguments = { mentor_id: mentor.id }

        def teacher_full_name
          Teachers::Name.new(mentor.teacher).full_name
        end
      end
    end
  end
end
