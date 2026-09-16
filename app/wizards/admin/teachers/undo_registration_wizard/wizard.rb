module Admin
  module Teachers
    module UndoRegistrationWizard
      class Wizard < ApplicationWizard
        attr_accessor :store, :teacher_id, :author

        steps do
          [{
            start: StartStep,
            confirm: ConfirmStep,
            confirmation: ConfirmationStep
          }]
        end

        def self.step?(step_name) = Array(steps).first[step_name].present?

        def allowed_steps
          return [:confirmation] if store.registration_undone
          return [:start] unless at_school_period

          %i[start confirm]
        end

        def allowed_step_path
          step_path(allowed_steps.last)
        end

        def teacher
          @teacher ||= Teacher.find(teacher_id)
        end

        def teacher_name
          ::Teachers::Name.new(teacher).full_name
        end

        def ect_at_school_periods
          @ect_at_school_periods ||= teacher.ect_at_school_periods
        end

        def mentor_at_school_periods
          @mentor_at_school_periods ||= teacher.mentor_at_school_periods
        end

        def at_school_periods
          @at_school_periods ||= ect_at_school_periods + mentor_at_school_periods
        end

        def at_school_period
          at_school_periods.first if at_school_periods.one?
        end

        def current_step_path
          step_path(current_step_name)
        end

        def next_step_path
          step_path(current_step.next_step)
        end

        def previous_step_path
          step_path(current_step.previous_step)
        end

      private

        def step_path(step_name)
          return if step_name.blank?

          Rails.application.routes.url_helpers.public_send(
            "admin_teacher_undo_registration_wizard_#{step_name}_path",
            teacher_id
          )
        end
      end
    end
  end
end
