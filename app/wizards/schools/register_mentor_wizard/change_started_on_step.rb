module Schools
  module RegisterMentorWizard
    class ChangeStartedOnStep < StartedOnStep
      def next_step
        :check_answers
      end

      def previous_step
        :check_answers
      end
    end
  end
end
