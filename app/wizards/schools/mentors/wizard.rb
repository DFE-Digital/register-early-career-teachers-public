module Schools
  module Mentors
    class Wizard < ApplicationWizard
      attr_accessor :store, :mentor_at_school_period, :author

      def self.step?(step_name)
        Array(steps).first[step_name].present?
      end

      # @return [String]
      def teacher_full_name
        ::Teachers::Name.new(mentor_at_school_period.teacher).full_name
      end

      # @return [Hash]
      def default_path_arguments
        { mentor_id: mentor_at_school_period.id }
      end

      # @return [String] not needed in next gem release
      def current_step_path
        super(default_path_arguments)
      end
    end
  end
end
