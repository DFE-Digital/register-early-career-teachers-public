module Schools
  module RegisterMentorWizard
    class CheckAnswersStep < Step
      def next_step
        :confirmation
      end

    private

      def registered_mentor
        mentor.register!(author: current_user)
      end

      def persist
        AssignMentor.new(ect:, mentor: registered_mentor, author: current_user).assign!
      end
    end
  end
end
