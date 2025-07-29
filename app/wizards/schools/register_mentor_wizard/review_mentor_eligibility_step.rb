module Schools
  module RegisterMentorWizard
    class ReviewMentorEligibilityStep < Step
      def next_step
        return :check_answers unless mentor.previously_registered_as_mentor?

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

    private

      def persist
        mentor.update!(lead_provider_id: mentor.ect_lead_provider&.id)
      end
    end
  end
end
