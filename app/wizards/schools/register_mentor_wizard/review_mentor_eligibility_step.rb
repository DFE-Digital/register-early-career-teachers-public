module Schools
  module RegisterMentorWizard
    class ReviewMentorEligibilityStep < Step
      def next_step
        return :check_answers unless mentor.has_mentor_at_school_periods?

        if mentor.has_open_mentor_at_school_period_at_another_school?
          # Ask school: are they mentoring at new school only?
          :mentoring_at_new_school_only
        else
          # Ask school: when will mentor start?
          :started_on
        end
      end

      def previous_step
        :email_address
      end
    end
  end
end
