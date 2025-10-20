module Schools
  module Mentors
    class Step < ApplicationWizardStep
      def self.permitted_params = []

      private

      delegate :mentor_at_school_period, :author, :valid_step?, to: :wizard

      def pre_populate_attributes = nil
    end
  end
end
