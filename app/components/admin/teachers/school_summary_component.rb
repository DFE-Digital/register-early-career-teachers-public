module Admin
  module Teachers
    class SchoolSummaryComponent < ApplicationComponent
      include TeacherHelper

      class UnexpectedSchoolPeriodError < StandardError; end

      attr_reader :school_period

      def initialize(school_period:)
        @school_period = school_period
      end

      def call
        govuk_summary_card(title: card_title) do |card|
          card.with_summary_list do |list|
            rows.each do |row|
              list.with_row do |r|
                r.with_key(text: row[:key][:text])
                if row[:value][:html]
                  r.with_value { row[:value][:html] }
                else
                  r.with_value(text: row[:value][:text])
                end
              end
            end
          end
        end
      end

    private

      def card_title
        govuk_link_to(school_period.school.name, admin_school_overview_path(school_period.school.urn))
      end

      def rows
        case school_period
        when ECTAtSchoolPeriod
          ect_rows
        when MentorAtSchoolPeriod
          mentor_rows
        else
          raise UnexpectedSchoolPeriodError, "Unexpected school period: #{school_period.class.name}"
        end
      end

      def base_rows
        [
          summary_row("School URN", school_period.school.urn),
          summary_row("School start date", school_period.started_on&.to_fs(:govuk)),
          summary_row("School end date", end_date_text),
          summary_row("Email address", email_text)
        ]
      end

      def ect_rows
        base_rows.tap do |rows|
          rows << summary_row("Appropriate body", appropriate_body_text)
          rows << summary_row("Assigned mentor", mentors_text, html: true)
          rows << summary_row("Working pattern", working_pattern_text)
        end
      end

      def mentor_rows
        base_rows.tap do |rows|
          rows << summary_row("Assigned ECTs", mentees_text, html: true)
        end
      end

      def end_date_text
        school_period.finished_on.present? ? school_period.finished_on&.to_fs(:govuk) : "No end date recorded"
      end

      def email_text
        school_period.email.presence || "Not available"
      end

      def appropriate_body_text
        school_period.school_reported_appropriate_body_name.presence || "No appropriate body recorded"
      end

      def mentorship_periods_for_ect
        school_period.mentorship_periods.includes(mentor: :teacher).order(started_on: :desc)
      end

      def mentorship_periods_for_mentor
        school_period.mentorship_periods.includes(mentee: :teacher).order(started_on: :desc)
      end

      def mentors_text
        mentor_links = mentorship_periods_for_ect.map { |period| mentor_link(period) }.compact
        return "None assigned" if mentor_links.empty?

        safe_join(mentor_links, tag.br)
      end

      def mentees_text
        mentee_links = mentorship_periods_for_mentor.map { |period| mentee_link(period) }.compact
        return "None assigned" if mentee_links.empty?

        safe_join(mentee_links, tag.br)
      end

      def mentor_link(mentorship_period)
        mentor_teacher = mentorship_period.mentor&.teacher
        return unless mentor_teacher

        govuk_link_to(teacher_full_name(mentor_teacher), admin_teacher_induction_path(mentor_teacher))
      end

      def mentee_link(mentorship_period)
        ect_teacher = mentorship_period.mentee&.teacher
        return unless ect_teacher

        govuk_link_to(teacher_full_name(ect_teacher), admin_teacher_induction_path(ect_teacher))
      end

      def working_pattern_text
        WORKING_PATTERNS[school_period.working_pattern&.to_sym] || "Not available"
      end

      def summary_row(label, value, html: false)
        {
          key: { text: label },
          value: html ? { html: value } : { text: value }
        }
      end
    end
  end
end
