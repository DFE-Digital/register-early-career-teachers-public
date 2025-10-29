module Schools
  module ECTs
    module ChangeMentorWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def current_mentor_name = name_for(current_mentor_at_school_period.teacher)

      private

        def current_mentor_at_school_period
          ect_at_school_period.current_or_next_mentorship_period.mentor
        end
      end
    end
  end
end
