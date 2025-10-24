module Schools
  module Mentors
    class Wizard < ApplicationWizard
      attr_accessor :store, :mentor_at_school_period, :author, :lead_provider

      def self.step?(step_name)
        Array(steps).first[step_name].present?
      end

      # @return [String]
      def teacher_full_name
        ::Teachers::Name.new(mentor_at_school_period.teacher.reload).full_name
      end

      # @return [Hash]
      def default_path_arguments
        { mentor_id: mentor_at_school_period.id }
      end

      # @return [LeadProvider] ???
      def lead_provider_id
        # TODO - this is wrong, might there be a service?
        mentor_at_school_period.training_periods.first.active_lead_provider.id
      end

      delegate :save!, to: :current_step
      delegate :reset, to: :store
    end
  end
end
