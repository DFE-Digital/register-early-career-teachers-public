module Schools
  module Mentors
    class ECTMentorTrainingDetailsComponent < ViewComponent::Base
      include TeacherHelper

      attr_reader :teacher, :mentor

      def initialize(teacher:, mentor:)
        @teacher = teacher
        @mentor = mentor
      end

      def render?
        assigned_ects.any?(&:provider_led_training_programme?)
      end

      def eligible_for_training?
        teacher.mentor_became_ineligible_for_funding_on.nil?
      end

      def first_lead_provider_name
        assigned_ects
          .order(:started_on)
          .detect do |ect|
            name = ECTAtSchoolPeriods::CurrentTraining.new(ect).lead_provider_name
            return name if name
          end
      end

      def assigned_ects
        @assigned_ects ||= @mentor.currently_assigned_and_transferring_ects
      end
    end
  end
end
