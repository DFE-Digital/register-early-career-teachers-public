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
        assigned_ects.any?(&:provider_led?)
      end

      def eligible_for_training?
        teacher.mentor_completion_date.nil?
      end

      def first_lead_provider_name
        assigned_ects
          .select { |ect| ect.lead_provider.present? }
          .min_by(&:started_on)
          &.lead_provider
          &.name
      end

      def assigned_ects
        @assigned_ects ||= @mentor.currently_assigned_ects
      end
    end
  end
end
