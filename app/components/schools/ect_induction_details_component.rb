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
      return appropriate_body_without_change_link_row unless can_change_appropriate_body?

      change_link = { actions: [{
        text: "Change",
        visually_hidden_text: "appropriate body",
        href: change_appropriate_body_path,
        classes: "govuk-link--no-visited-state"
      }] }

      appropriate_body_without_change_link_row.merge(change_link)
    end

    def appropriate_body_without_change_link_row
      { key: { text: "Appropriate body" }, value: { text: appropriate_body_text } }
    end

    def can_change_appropriate_body?
      @ect.teacher.ongoing_induction_period.nil?
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

    def appropriate_body_text
      @ect.school_reported_appropriate_body_name.presence || "Not reported"
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
