module Schools
  module RegisterMentorWizard
    class PreviousTrainingPeriodDetailsStep < Step
      def next_step
        :programme_choices
      end

      def previous_step
        :started_on
      end

    private

      def persist
        ActiveRecord::Base.transaction do
          AssignMentor.new(ect:, author:, mentor: mentor.register!(author:)).assign!
        end
      rescue StandardError => e
        mentor.registered = false
        raise e
      end
    end
  end
end
