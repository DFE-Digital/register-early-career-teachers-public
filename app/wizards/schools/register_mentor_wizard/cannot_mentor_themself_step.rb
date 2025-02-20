# frozen_string_literal: true

module Schools
  module RegisterMentorWizard
    class CannotMentorThemselfStep < Step
      def previous_step
        :find_mentor
      end
    end
  end
end
