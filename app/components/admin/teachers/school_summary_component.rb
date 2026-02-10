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
          card.with_summary_list(actions: false) do |list|
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
          rows << summary_row("Working pattern", working_pattern_text)
          rows << summary_row("Mentor", mentors_content, html: true)
        end
      end

      def mentor_rows
        base_rows.tap do |rows|
          rows << summary_row("Assigned ECTs", mentees_content, html: true)
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

      def mentors_content
        periods = mentorship_periods_for_ect
        return "None assigned" if periods.empty?

        mentorship_table(periods, :mentor)
      end

      def mentees_content
        periods = mentorship_periods_for_mentor
        return "None assigned" if periods.empty?

        mentorship_table(periods, :mentee)
      end

      def mentorship_table(periods, role)
        govuk_table(
          first_cell_is_header: false,
          head: ["Name", "Start date", "End date"],
          rows: periods.filter_map { mentorship_table_row(it, role) }
        )
      end

      def mentorship_table_row(mentorship_period, role)
        teacher = role == :mentor ? mentorship_period.mentor&.teacher : mentorship_period.mentee&.teacher
        return unless teacher

        [
          govuk_link_to(teacher_full_name(teacher), admin_teacher_induction_path(teacher)),
          mentorship_period.started_on.to_fs(:govuk),
          mentorship_end_date_text(mentorship_period)
        ]
      end

      def mentorship_end_date_text(mentorship_period)
        mentorship_period.finished_on.present? ? mentorship_period.finished_on.to_fs(:govuk) : "Present"
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
