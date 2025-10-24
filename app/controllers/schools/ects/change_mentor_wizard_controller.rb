module Schools
  module ECTs
    class ChangeMentorWizardController < SchoolsController
      include Wizardable
      before_action :register_mentor, only: %i[new create]

      wizard_for :ect

      def new
        render @current_step
      end

      def create
        if @wizard.save!
          redirect_to @wizard.next_step_path
        else
          render @current_step, status: :unprocessable_content
        end
      end

    private

      def register_mentor
        case action_name
        when "new"
          redirect_to_register_mentor_wizard unless mentors_registered?
        when "create"
          redirect_to_register_mentor_wizard if new_mentor?
        end
      end

      def redirect_to_register_mentor_wizard
        redirect_to schools_register_mentor_wizard_start_path(ect_id: @wizard.ect_at_school_period.id)
      end

      def mentor_id
        @mentor_id ||= params.dig(:edit, :mentor_at_school_period_id)
      end

      def new_mentor?
        mentor_id == "0"
      end

      def mentors_registered?
        school.mentor_at_school_periods.ongoing.exists?
      end
    end
  end
end
