module Schools
  module RegisterMentorWizard
    class ChangeStartedOnStep < StartedOnStep
      def next_step
        if !mentor.contract_period_enabled?
          :cannot_register_mentor_yet
        else
          :check_answers
        end
      end

      # TODO backlink navigation
      def previous_step
        :check_answers
      end
    end
  end
end
