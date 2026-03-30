module Schools
  module ECTs
    class ChangeEmailAddressWizardController < SchoolsController
      include Schools::InductionRedirectable

      include Wizardable

      wizard_for :ect

      before_action -> { redirect_to @wizard.previous_step_path },
                    if: -> { @current_step == :check_answers && session[form_key].blank? }

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
    end
  end
end
