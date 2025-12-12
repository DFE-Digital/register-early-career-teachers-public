module Schools
  module InductionRedirectable
    extend ActiveSupport::Concern

    included do
      before_action :redirect_to_induction_wizard, if: :induction_information_needs_update?
    end

  private

    def redirect_to_induction_wizard
      redirect_to(induction_details_service.wizard_path)
    end

    def induction_information_needs_update?
      induction_details_service.update_required?
    end

    def induction_details_service
      @induction_details_service ||= Schools::InductionTutorDetails.new(current_user)
    end
  end
end
