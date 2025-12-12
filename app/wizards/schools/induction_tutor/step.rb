module Schools
  module InductionTutor
    class Step < ApplicationWizardStep
      def self.permitted_params = []

    private

      delegate :school, :author, :valid_step?, :current_contract_period, to: :wizard

      def pre_populate_attributes = nil
    end
  end
end
