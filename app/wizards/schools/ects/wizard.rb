module Schools
  module ECTs
    class Wizard < ApplicationWizard
      attr_accessor :store, :ect_at_school_period, :author

      def self.step?(step_name)
        Array(steps).first[step_name].present?
      end

      # @return [String]
      def name_for(...) = ::Teachers::Name.new(...).full_name

      # @return [String]
      def teacher_full_name
        name_for(ect_at_school_period.teacher.reload)
      end

      def details_path
        url_helpers.schools_ect_path(ect_at_school_period)
      end

      def mentor? = false

      # @return [Hash]
      def default_path_arguments
        { ect_id: ect_at_school_period.id }
      end

      delegate :teacher, to: :ect_at_school_period
      delegate :save!, to: :current_step
      delegate :reset, to: :store
    end
  end
end
