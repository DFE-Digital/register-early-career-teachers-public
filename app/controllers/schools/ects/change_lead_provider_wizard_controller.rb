module Schools
  module ECTs
    class ChangeLeadProviderWizardController < SchoolsController
      include Schools::InductionRedirectable

      include Wizardable

      before_action :ensure_provider_led!

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

      def ensure_provider_led!
        return if @ect_at_school_period&.provider_led_training_programme?

        render "errors/not_found", status: :not_found
      end
    end
  end
end
