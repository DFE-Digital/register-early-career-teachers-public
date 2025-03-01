module Schools
  module RegisterMentorWizard
    class ReviewMentorEligibilityStep < Step
      def next_step
        :check_answers
      end
    end
  end
end
