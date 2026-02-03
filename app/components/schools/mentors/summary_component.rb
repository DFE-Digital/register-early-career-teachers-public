module Schools
  module Mentors
    class SummaryComponent < ApplicationComponent
      include TeacherHelper

      # with_collection_parameter :mentor

      attr_reader :mentor, :school

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

      def training_period_summary_rows
        return [] unless latest_training_period

        [
          { key: { text: "Lead provider" }, value: { text: provider_display_with_status } },
          { key: { text: "Delivery partner" }, value: { text: delivery_partner_name } },
        ]
      end

      # TODO: N+1 queries
      def latest_training_period
        @latest_training_period ||= mentor_period_for_school&.latest_training_period
      end

      def lead_provider_name
        @lead_provider_name ||= latest_training_period&.lead_provider_name
      end

      def status_text
        case
        when partnership_confirmed?
          "Confirmed by #{lead_provider_name}"
        when latest_training_period.only_expression_of_interest?
          "Awaiting confirmation by #{lead_provider_name}"
        end
      end

      def provider_display_with_status
        safe_join([
          lead_provider_name,
          tag.br,
          tag.span(status_text, class: "govuk-hint")
        ])
      end

      def partnership_confirmed?
        latest_training_period.school_partnership.present?
      end

      # TODO: N+1 queries
      def delivery_partner_name
        latest_training_period&.delivery_partner_name
      end

      # TODO: N+1 queries
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
