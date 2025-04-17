module Schools
  module Mentors
    class DetailsComponent < ViewComponent::Base
      include TeacherHelper

      def initialize(teacher:, mentor:)
        @teacher = teacher
        @mentor = mentor
      end

      def call
        safe_join([
          tag.h2('Mentor details', class: 'govuk-heading-m'),
          govuk_summary_list(rows:)
        ])
      end

      def rows
        [
          name_row,
          email_row,
          assigned_ects_row
        ]
      end

    private

      def name_row
        {
          key: { text: 'Name' },
          value: { text: teacher_full_name(@teacher) }
        }
      end

      def email_row
        {
          key: { text: 'Email address' },
          value: { text: @mentor.email }
        }
      end

      def assigned_ects_row
        {
          key: { text: 'Assigned ECTs' },
          value: {
            text: assigned_ects_value
          }
        }
      end

      def assigned_ects_value
        return 'No ECTs assigned' if assigned_ects.empty?

        safe_join(assigned_ects.map do |ect|
          govuk_link_to(
            teacher_full_name(ect.teacher),
            schools_ect_path(ect, back_to_mentor: true, mentor_id: @mentor.id)
          )
        end, tag.br)
      end

      def assigned_ects
        @assigned_ects ||= @mentor.currently_assigned_ects
      end
    end
  end
end
