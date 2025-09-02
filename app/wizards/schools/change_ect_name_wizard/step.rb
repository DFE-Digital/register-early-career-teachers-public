module Schools
  module ChangeECTNameWizard
    class Step < ApplicationWizardStep
      def self.permitted_params = []

      def pre_populate_attributes
        # no-op
      end
    end
  end
end
