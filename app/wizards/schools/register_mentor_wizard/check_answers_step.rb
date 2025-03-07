module Schools
  module RegisterMentorWizard
    class CheckAnswersStep < Step
      def next_step
        :confirmation
      end

      def previous_step
        mentor.funding_available? ? :review_mentor_eligibility : :email_address
      end

    private

      def persist
        AssignMentor.new(ect:, mentor: mentor.register!).assign!
      end
    end
  end
end
