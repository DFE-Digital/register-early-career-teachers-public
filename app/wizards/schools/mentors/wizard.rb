module Schools
  module Mentors
    class Wizard < ApplicationWizard
      attr_accessor :store, :mentor_at_school_period, :author

      def self.step?(step_name)
        Array(steps).first[step_name].present?
      end

      # @return [String]
      def name_for(...) = ::Teachers::Name.new(...).full_name

      # @return [String]
      def teacher_full_name
        ::Teachers::Name.new(mentor_at_school_period.teacher.reload).full_name
      end

      def teacher_trn
        mentor_at_school_period.teacher.trn
      end

      def details_path
        url_helpers.schools_mentor_path(mentor_at_school_period)
      end

      # @return [Hash]
      def default_path_arguments
        { mentor_id: mentor_at_school_period.id }
      end

      delegate :teacher, to: :mentor_at_school_period
      delegate :save!, to: :current_step
      delegate :reset, to: :store
    end
  end
end
