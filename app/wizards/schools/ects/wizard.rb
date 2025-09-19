module Schools
  module ECTs
    class Wizard < ApplicationWizard
      attr_accessor :store, :ect_at_school_period, :author

      def self.step?(step_name)
        Array(steps).first[step_name].present?
      end

      # @return [String]
      def teacher_full_name
        ::Teachers::Name.new(ect_at_school_period.teacher.reload).full_name
      end

      # @return [Hash]
      def default_path_arguments
        { ect_id: ect_at_school_period.id }
      end

      delegate :save!, to: :current_step
      delegate :reset, to: :store
    end
  end
end
