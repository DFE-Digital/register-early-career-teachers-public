module Schools
  module RegisterMentorWizard
    class PreviousTrainingPeriodDetailsStep < Step
      def next_step
        :programme_choices
      end

      def previous_step
        :started_on
      end
    end
  end
end
