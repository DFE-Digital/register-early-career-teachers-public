module Schools
  module ECTs
    class ChangeStartDateWizardController < SchoolsController
      include Schools::InductionRedirectable
      include Wizardable

      wizard_for :ect

      before_action :ensure_eligible!

      def new
        render @current_step
      end

      def create
        if @wizard.save!
          redirect_to @wizard.next_step_path
        else
          render @current_step,
                 status: :unprocessable_content
        end
      end

    private

      def ensure_eligible!
        return if eligible_to_change_start_date?

        render "errors/not_found", status: :not_found
      end

      def eligible_to_change_start_date?
        ECTAtSchoolPeriods::ChangeStartDate::Eligibility
          .new(ect_at_school_period: @ect_at_school_period)
          .eligible?
      end
    end
  end
end
