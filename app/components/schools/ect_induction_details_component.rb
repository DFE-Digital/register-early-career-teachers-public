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
      date = induction_start_date
      return induction_start_date_not_reported_row if date.blank?

      {
        key: { text: "Induction start date" },
        value: { text: induction_start_date_with_suffix(date) }
      }
    end

    def induction_start_date
      induction.induction_start_date&.to_fs(:govuk)
    end

    def induction_start_date_with_suffix(date)
      safe_join([
        date,
        tag.br,
        tag.span("This has been reported by an appropriate body", class: "govuk-hint")
      ])
    end

    def appropriate_body_text
      appropriate_body_name.presence || "Not reported"
    end

    def appropriate_body_name
      if induction.has_induction_periods?
        induction.latest_induction_period&.appropriate_body_name
      else
        @ect.school_reported_appropriate_body_name
      end
    end

    def induction
      @induction ||= Teachers::Induction.new(@ect.teacher)
    end

    def induction_start_date_not_reported_row
      {
        key: { text: "Induction start date" },
        value: { text: "Yet to be reported by the appropriate body" }
      }
    end
  end
end
