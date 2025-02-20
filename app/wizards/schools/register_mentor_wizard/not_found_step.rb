module Schools
  module RegisterMentorWizard
    class NotFoundStep < Step
      def previous_step
        :find_mentor
      end
    end
  end
end
