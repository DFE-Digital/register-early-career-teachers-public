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
        return if ECTAtSchoolPeriods::ChangeStartDate::Eligibility
          .new(ect_at_school_period: @ect_at_school_period)
          .eligible?

        raise ActiveRecord::RecordNotFound
      end
    end
  end
end
