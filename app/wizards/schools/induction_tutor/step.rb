module Schools
  module InductionTutor
    class Step < ApplicationWizardStep
      delegate :school, :author, :valid_step?, :current_contract_period, to: :wizard

      def self.permitted_params = []

    private

      def pre_populate_attributes = nil
    end
  end
end
