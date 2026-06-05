module Schools
  module InductionTutor
    class NewInductionTutorWizardController < SchoolsController
      include InductionTutorable

      before_action :redirect_when_no_contract_period

    private

      def redirect_when_no_contract_period
        return if ContractPeriod.current_or_upcoming.present?

        redirect_to schools_induction_tutor_path,
                    alert: "You cannot assign or confirm an induction tutor at this time"
      end
    end
  end
end
