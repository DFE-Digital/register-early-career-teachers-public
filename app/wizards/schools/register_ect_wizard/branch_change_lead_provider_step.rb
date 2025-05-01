module Schools
  module RegisterECTWizard
    class BranchChangeLeadProviderStep < LeadProviderStep
      def next_step
        :check_answers
      end

      def previous_step
        return :branch_change_programme_type if school.programme_choices? || ect.lead_provider_id.nil?

        :check_answers
      end
    end
  end
end
