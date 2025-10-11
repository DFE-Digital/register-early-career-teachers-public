module Schools
  module ECTs
    module ChangeMentorWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_mentor = current_mentor_at_school_period.teacher
      end
    end
  end
end
