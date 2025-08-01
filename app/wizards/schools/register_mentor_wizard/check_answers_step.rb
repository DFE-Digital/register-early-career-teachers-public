module Schools
  module RegisterMentorWizard
    class CheckAnswersStep < Step
      def next_step
        :confirmation
      end

      def previous_step
        return :review_mentor_eligibility if ect.provider_led_training_programme? && mentor.funding_available?

        :email_address
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
