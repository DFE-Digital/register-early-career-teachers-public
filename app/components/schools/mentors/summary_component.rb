module Schools
  module Mentors
    class SummaryComponent < ApplicationComponent
      include TeacherHelper

      with_collection_parameter :mentor

      def initialize(mentor:, school:)
        @mentor = mentor
        @school = school
      end

    private

      delegate :trn, to: :@mentor

      def link_to_mentor
        govuk_link_to(teacher_full_name(@mentor), schools_mentor_path(mentor_period_for_school))
      end

      def link_to_ect(ect)
        govuk_link_to(teacher_full_name(ect.teacher), schools_ect_path(ect))
      end

      def trn_row
        { key: { text: "TRN" }, value: { text: trn } }
      end

      def assigned_ects_row
        { key: { text: "Assigned ECTs" }, value: { text: assigned_ects_summary } }
      end

      def mentor_period_for_school
        @mentor.mentor_at_school_periods.find_by(school: @school)
      end

      def assigned_ects
        @assigned_ects ||= (mentor_period_for_school&.current_or_future_ects).to_a
      end

      def assigned_ects_summary
        ects = assigned_ects
        return "No ECTs assigned" if ects.empty?
        return "#{ects.length} assigned ECTs" if ects.length > 5

        safe_join(ects.map { link_to_ect(it) }, tag.br)
      end
    end
  end
end
