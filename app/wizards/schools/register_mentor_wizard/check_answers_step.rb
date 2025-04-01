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
        ActiveRecord::Base.transaction do
          AssignMentor.new(ect:, mentor: mentor.register!).assign!
        end
      rescue StandardError => e
        mentor.registered = false
        raise e
      end
    end
  end
end
