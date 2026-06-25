module Schools
  class ECTInductionDetailsComponent < ApplicationComponent
    include TeacherHelper

    def initialize(ect)
      @ect = ect
    end

    def call
      safe_join([
        tag.h2("Induction details", class: "govuk-heading-m"),
        govuk_summary_list(rows:)
      ])
    end

  private

    def rows
      [
        appropriate_body_row,
        induction_start_date_row
      ]
    end

    def appropriate_body_row
      {
        key: { text: "Appropriate body" },
        value: { text: appropriate_body_html },
        actions: [change_appropriate_body_link].compact
      }
    end

    def change_appropriate_body_link
      return unless @ect.teacher.ongoing_induction_period.nil?

      {
        text: "Change",
        visually_hidden_text: "appropriate body",
        href: change_appropriate_body_path,
        classes: "govuk-link--no-visited-state"
      }
    end

    def induction_start_date_row
      date = induction_start_date
      return induction_start_date_not_reported_row if date.blank?

      {
        key: { text: "Induction start date" },
        value: { text: induction_start_date_with_suffix(date) }
      }
    end

    def induction_start_date
      Teachers::Induction.new(@ect.teacher).induction_start_date&.to_fs(:govuk)
    end

    def induction_start_date_with_suffix(date)
      safe_join([
        date,
        tag.br,
        tag.span("This has been reported by an appropriate body", class: "govuk-hint")
      ])
    end

    def appropriate_body_html
      name = @ect.school_reported_appropriate_body_name.presence
      return "Not reported" if name.nil?

      safe_join([
        name,
        tag.br,
        tag.span(appropriate_body_status, class: "govuk-hint")
      ])
    end

    def appropriate_body_status
      if @ect.claimed_by_school_reported_appropriate_body?
        safe_join([
          "This appropriate body has recorded the ECT’s induction.",
          tag.br,
          "Contact them if this is wrong or if you want to change the appropriate body."
        ])
      else
        "Awaiting confirmation by the appropriate body"
      end
    end

    def induction_start_date_not_reported_row
      {
        key: { text: "Induction start date" },
        value: { text: "Yet to be reported by the appropriate body" }
      }
    end

    def change_appropriate_body_path
      schools_ects_change_appropriate_body_wizard_edit_path(ect_id: @ect.id)
    end
  end
end
