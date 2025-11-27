module Schools
  module Induction
    class Wizard < ApplicationWizard
      attr_accessor :store, :school, :author

      def self.step?(step_name)
        Array(steps).first[step_name].present?
      end

      # @return [Hash]
      def default_path_arguments
        { school_id: school.id }
      end

      delegate :save!, to: :current_step
      delegate :reset, to: :store
    end
  end
end
