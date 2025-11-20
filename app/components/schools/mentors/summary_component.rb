module Schools
  module Mentors
    class SummaryComponent < ApplicationComponent
      include TeacherHelper

      with_collection_parameter :mentor

      def initialize(mentor:, school:)
        @mentor = mentor
        @school = school
      end

      def call
        govuk_summary_card(title: link_to_mentor) do |card|
          card.with_summary_list(
            classes: %w[govuk-summary-list--no-border],
            rows: [trn_row, assigned_ects_row]
          )
        end
      end

    private

      def link_to_mentor
        govuk_link_to(teacher_full_name(@mentor), schools_mentor_path(mentor_period_for_school))
      end

      def trn_row
        { key: { text: "TRN" }, value: { text: trn } }
      end

      def assigned_ects_row
        { key: { text: "Assigned ECTs" }, value: { text: assigned_ects_summary } }
      end

      def trn
        @mentor.trn
      end

      def mentor_period_for_school
        @mentor.mentor_at_school_periods.find_by(school: @school)
      end

      def assigned_ects
        @assigned_ects ||= (mentor_period_for_school&.currently_assigned_ects).to_a
      end

      def assigned_ects_summary
        ects = assigned_ects
        return "No ECTs assigned" if ects.empty?
        return "#{ects.length} assigned ECTs" if ects.length > 5

        safe_join(ects.map { |ect| teacher_full_name(ect.teacher) }, tag.br)
      end
    end
  end
end
