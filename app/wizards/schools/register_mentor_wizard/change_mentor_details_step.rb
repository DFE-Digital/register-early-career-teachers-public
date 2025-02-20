module Schools
  module RegisterMentorWizard
    class ChangeMentorDetailsStep < ReviewMentorDetailsStep
      def next_step
        :check_answers
      end

      def previous_step
        :check_answers
      end
    end
  end
end
