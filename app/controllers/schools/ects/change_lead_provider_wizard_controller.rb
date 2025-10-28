module Schools
  module ECTs
    class ChangeLeadProviderWizardController < SchoolsController
      include Wizardable

      before_action :render_not_found_if_school_led_training_programme!

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

      def render_not_found_if_school_led_training_programme!
        ect_at_school_period = ECTAtSchoolPeriod.find_by(id: params[:ect_id])

        if ect_at_school_period&.current_or_next_training_period&.school_led_training_programme?
          render "errors/not_found", status: :not_found
        end
      end
    end
  end
end
