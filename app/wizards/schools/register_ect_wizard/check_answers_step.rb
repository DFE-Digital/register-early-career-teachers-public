module Schools
  module RegisterECTWizard
    class CheckAnswersStep < Step
      def next_step
        :confirmation
      end

      def previous_step
        return :use_previous_ect_choices if ect.use_previous_ect_choices

        ect.provider_led? ? :lead_provider : :training_programme
      end

    private

      def persist
        ect_at_school_period_id = ect.register!(school, author: wizard.author, store: wizard.store).id
        ect.update!(ect_at_school_period_id:)
      end
    end
  end
end
