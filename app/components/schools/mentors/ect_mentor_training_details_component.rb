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
        teacher.mentor_became_ineligible_for_funding_on.nil?
      end

      def first_lead_provider_name
        lead_provider&.name
      end

      def assigned_ects
        @assigned_ects ||= @mentor.currently_assigned_ects
      end

    private

      def lead_provider
        ECTAtSchoolPeriods::Training.new(assigned_ects.select(&:present?).min_by(&:started_on))&.latest_lead_provider
      end
    end
  end
end
