module Schools
  module AssignExistingMentorWizard
    class Wizard < DfE::Wizard::Base
      attr_accessor :store, :ect_id, :mentor_period_id, :author

      steps do
        [{
          review_mentor_eligibility: ReviewMentorEligibilityStep,
          lead_provider: LeadProviderStep,
          confirmation: ConfirmationStep
        }]
      end

      def self.step?(step_name) = Array(steps).first[step_name].present?

      def allowed_step?(step_name = current_step_name)
        allowed_steps.include?(step_name)
      end

      def mentor_assignment_context
        # Convenience accessors for key objects used throughout the wizard
        @mentor_assignment_context ||= Shared::MentorAssignmentContext.new(
          store:,
          mentor_at_school_period:,
          ect_at_school_period:
        )
      end

      alias_method :context, :mentor_assignment_context

    private

      def allowed_steps = %i[review_mentor_eligibility lead_provider confirmation]

      def mentor_at_school_period
        @mentor_at_school_period ||= MentorAtSchoolPeriod.find(mentor_period_id)
      end

      def ect_at_school_period
        @ect_at_school_period ||= ECTAtSchoolPeriod.find(ect_id)
      end
    end
  end
end
