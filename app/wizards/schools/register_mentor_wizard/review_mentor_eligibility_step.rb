module Schools
  module RegisterMentorWizard
    class ReviewMentorEligibilityStep < Step
      def next_step
        :check_answers
      end

      def previous_step
        :email_address
      end
    end
  end
end
