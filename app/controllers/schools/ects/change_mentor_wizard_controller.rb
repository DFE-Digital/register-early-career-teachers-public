module Schools
  module ECTs
    class ChangeMentorWizardController < SchoolsController
      include Wizardable
      wizard_for :ect

      before_action :redirect_to_register_mentor_if_needed, only: %i[new create]

      def new
        @wizard.new_mentor_requested = params[:new_mentor_requested]
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

      def redirect_to_register_mentor_if_needed
        case action_name
        when "new"
          redirect_to_register_mentor_wizard unless mentors_registered?
        when "create"
          redirect_to_register_mentor_wizard if new_mentor?
        end
      end

      def redirect_to_register_mentor_wizard
        redirect_to schools_register_mentor_wizard_start_path(ect_id: @wizard.ect_at_school_period.id, new_mentor_requested: true)
      end

      def mentor_id
        @mentor_id ||= @wizard.current_step.attributes["mentor_at_school_period_id"]
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
