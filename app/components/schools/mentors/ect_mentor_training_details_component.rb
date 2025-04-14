module Schools
  module Mentors
    class ECTMentorTrainingDetailsComponent < ViewComponent::Base
      include TeacherHelper

      attr_reader :teacher, :mentor, :ects

      def initialize(teacher:, mentor:, ects:)
        @teacher = teacher
        @mentor = mentor
        @ects = ects
      end

      def render?
        ects.any? { |ect| ect.programme_type == "provider_led" }
      end

      def eligible_for_training?
        teacher.mentor_completion_date.nil?
      end
    end
  end
end
