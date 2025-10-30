module API
  module TeacherType
    extend ActiveSupport::Concern

  protected

    def teacher_type
      course_identifier = params.dig(:data, :attributes, :course_identifier)

      case course_identifier
      when "ecf-induction"
        :ect
      when "ecf-mentor"
        :mentor
      end
    end
  end
end
