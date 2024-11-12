# frozen_string_literal: true

module Schools
  module RegisterECT
    class CheckAnswersStep < StoredStep
      def self.permitted_params
      end

      def next_step
        :confirmation
      end
    end
  end
end
