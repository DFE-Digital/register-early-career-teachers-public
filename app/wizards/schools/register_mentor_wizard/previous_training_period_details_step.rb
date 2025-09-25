module Schools
  module RegisterMentorWizard
    class PreviousTrainingPeriodDetailsStep < Step
      def next_step
        if mentor.ect_lead_provider_invalid?
          :lead_provider
        else
          :programme_choices
        end
      end

      def previous_step
        :started_on
      end
    end
  end
end
