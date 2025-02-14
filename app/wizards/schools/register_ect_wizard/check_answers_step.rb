module Schools
  module RegisterECTWizard
    class CheckAnswersStep < Step
      def next_step
        :confirmation
      end

      def previous_step
        ect.provider_led? ? :lead_provider : :programme_type
      end

    private

      def persist
        ect_at_school_period_id = ect.register!(school).id
        ect.update!(ect_at_school_period_id:)
      end
    end
  end
end
