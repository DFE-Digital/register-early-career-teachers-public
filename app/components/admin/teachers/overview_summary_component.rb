module Admin
  module Teachers
    class OverviewSummaryComponent < ApplicationComponent
      include TeacherHelper

      attr_reader :teacher

      def initialize(teacher:)
        @teacher = teacher
      end

      def call
        govuk_summary_list do |summary_list|
          rows.each do |row|
            summary_list.with_row do |summary_row|
              summary_row.with_key(text: row[:key])
              summary_row.with_value { row[:value] }
            end
          end
        end
      end

      def rows
        [
          name_row,
          trn_row,
          role_row,
          latest_email_row,
          current_school_row,
          induction_status_row,
          api_participant_id_row
        ].compact
      end

    private

      def name_value
        return teacher_full_name(teacher) unless full_name_in_trs_different?(teacher)

        safe_join([
          teacher_full_name(teacher),
          tag.br,
          tag.span("Name from TRS: #{teacher_full_name_in_trs(teacher)}", class: "govuk-hint")
        ])
      end

      def name_row
        { key: "Name", value: name_value }
      end

      def trn_row
        { key: "TRN", value: teacher.trn }
      end

      def role_row
        { key: "Role", value: teacher.roles.presence || "Not available" }
      end

      def latest_email_row
        { key: "Most recent email address", value: teacher.most_recent_email }
      end

      def current_school_row
        { key: "Current school", value: current_school_value }
      end

      def induction_status_row
        return unless teacher.induction_status

        { key: "Induction status", value: teacher.induction_status }
      end

      def api_participant_id_row
        { key: "API participant ID", value: content_tag(:code, teacher.api_participant_id, class: "app-code") }
      end

      def current_school_value
        return "Not currently registered at a school" if schools.empty?

        safe_join(schools.map { |school| school_link(school) }, tag.br)
      end

      def school_link(school)
        govuk_link_to("#{school.name} (URN: #{school.urn})", admin_school_overview_path(school.urn))
      end

      def schools
        teacher.current_schools
      end
    end
  end
end
