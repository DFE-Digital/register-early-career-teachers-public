module Schools
  module ECTs
    module ChangeLeadProviderWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_lead_provider_name = current_lead_provider&.name

      private

        def current_lead_provider
          @current_lead_provider ||= ECTAtSchoolPeriods::CurrentTraining
            .new(ect_at_school_period)
            .lead_provider_via_school_partnership_or_eoi
        end
      end
    end
  end
end
