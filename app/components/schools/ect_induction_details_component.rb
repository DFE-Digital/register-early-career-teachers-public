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
      { key: { text: "Appropriate body" }, value: { text: appropriate_body_text } }
    end

    def induction_start_date_row
      return induction_start_date_not_reported_row if appropriate_body_not_reported?

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
      return "Not reported" if appropriate_body_not_reported?

      @ect.school_reported_appropriate_body_name
    end

    def appropriate_body_not_reported?
      @ect.appropriate_body_not_reported?
    end

    def induction_start_date_not_reported_row
      {
        key: { text: "Induction start date" },
        value: { text: "Yet to be reported by the appropriate body" }
      }
    end
  end
end
