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
          return [] if at_school_periods.empty?
          return [:start] unless at_school_period

          %i[start confirm]
        end

        def allowed_step_path
          return teacher_school_path if allowed_steps.empty?

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

        def periods_will_be_closed?
          return @periods_will_be_closed if defined?(@periods_will_be_closed)

          @periods_will_be_closed = undo_registration.periods_will_be_closed?
        end

        delegate :finish_date_for, to: :undo_registration

        def undo_registration!
          undo_registration.undo!
        end

        def affected_training_periods
          @affected_training_periods ||= periods_affected(
            at_school_period.training_periods.includes(
              :schedule,
              :school_partnership,
              :lead_provider,
              :delivery_partner,
              :contract_period,
              :expression_of_interest_lead_provider,
              :expression_of_interest_contract_period
            )
          ).to_a
        end

        def affected_mentorship_periods
          @affected_mentorship_periods ||= periods_affected(
            at_school_period.mentorship_periods.includes(mentor: :teacher, mentee: :teacher)
          ).to_a
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

        def teacher_school_path
          Rails.application.routes.url_helpers.admin_teacher_school_path(teacher)
        end

        def undo_registration
          @undo_registration ||= ::Teachers::UndoRegistration.new(
            author:,
            at_school_period:,
            reason: :registered_in_error
          )
        end

        def periods_affected(periods)
          periods_will_be_closed? ? periods.unfinished : periods
        end

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
