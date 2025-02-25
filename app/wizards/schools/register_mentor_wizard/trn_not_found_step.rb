module Schools
  module RegisterMentorWizard
    class TRNNotFoundStep < Step
      def previous_step
        :find_mentor
      end
    end
  end
end
