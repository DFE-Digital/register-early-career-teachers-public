module Schools
  module Mentors
    class SummaryComponent < ViewComponent::Base
      include TeacherHelper

      def initialize(mentor:, school:)
        @mentor = mentor
        @school = school
      end

      def call
        govuk_summary_card(title: link_to_mentor(@mentor)) do |card|
          card.with_summary_list(
            classes: %w[govuk-summary-list--no-border],
            rows: [trn_row, assigned_ects_row]
          )
        end
      end

    private

      def link_to_mentor(mentor)
        govuk_link_to(teacher_full_name(mentor.teacher), schools_mentor_path(mentor))
      end

      def trn_row
        { key: { text: 'TRN' }, value: { text: trn } }
      end

      def assigned_ects_row
        { key: { text: 'Assigned ECTs' }, value: { text: assigned_ects_summary } }
      end

      def trn
        @mentor.teacher.trn
      end

      def assigned_ects
        @assigned_ects ||= @mentor.currently_assigned_ects
      end

      def assigned_ects_summary
        return "No ECTs assigned" if assigned_ects.empty?
        return "#{assigned_ects.count} assigned ECTs" if assigned_ects.count > 5

        safe_join(assigned_ects.map { |ect| teacher_full_name(ect.teacher) }, tag.br)
      end
    end
  end
end
