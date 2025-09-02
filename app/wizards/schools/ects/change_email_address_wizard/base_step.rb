module Schools
  module ECTs
    module ChangeEmailAddressWizard
      class BaseStep < ApplicationWizardStep
        def self.permitted_params = []

      private

        delegate :ect_at_school_period, :author, to: :wizard

        def pre_populate_attributes = nil
      end
    end
  end
end
