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
        href: schools_ects_change_appropriate_body_wizard_edit_path(@ect),
        classes: "govuk-link--no-visited-state"
      }
    end

    def appropriate_body
      @appropriate_body ||= ECTAtSchoolPeriods::AppropriateBody.new(@ect)
    end

    def appropriate_body_html
      return claimed_appropriate_body_html if appropriate_body.from_induction?
      return appropriate_body.name unless appropriate_body.from_school?

      safe_join([
        appropriate_body.name,
        tag.br,
        tag.span("Awaiting confirmation by the appropriate body", class: "govuk-hint")
      ])
    end

    def claimed_appropriate_body_html
      safe_join([
        appropriate_body.name,
        tag.br,
        tag.span(
          safe_join([
            "This appropriate body has recorded the ECT’s induction.",
            tag.br,
            "Contact them if this is wrong or if you want to change the appropriate body."
          ]),
          class: "govuk-hint"
        )
      ])
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

    def induction_start_date_not_reported_row
      {
        key: { text: "Induction start date" },
        value: { text: "Yet to be reported by the appropriate body" }
      }
    end
  end
end
