# frozen_string_literal: true

module Schools
  module RegisterECT
    class ReviewECTDetailsStep < StoredStep
      def self.permitted_params
      end

      def next_step
        :email_address
      end
    end
  end
end
