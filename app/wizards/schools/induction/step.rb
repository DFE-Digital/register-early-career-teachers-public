module Schools
  module Induction
    class Step < ApplicationWizardStep
      def self.permitted_params = []

    private

      delegate :school, :author, :valid_step?, to: :wizard

      def pre_populate_attributes = nil
    end
  end
end
