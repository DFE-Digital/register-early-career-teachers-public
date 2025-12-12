module Schools
  module Mentors
    class ChangeLeadProviderWizardController < SchoolsController
      include Schools::InductionRedirectable

      include Wizardable

      wizard_for :mentor

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
