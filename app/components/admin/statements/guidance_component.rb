module Admin::Statements
  class GuidanceComponent < ApplicationComponent
    erb_template <<~ERB
      <%=
        govuk_details(
          summary_text: "Calculation rounding errors",
          text: rounding_errors_text
        )
      %>

      <%=
        govuk_details(
          summary_text: "Updated financial statement design",
          text: updated_financial_statement_text
        )
      %>
    ERB

  private

    def rounding_errors_text
      <<~TXT.squish
        Due to the way payments per participant are made, there may be rounding
        errors in some of the individual sub-calculations. The total output fees
        displayed are correct. Contact your contract manager if you have any
        queries.
      TXT
    end

    def updated_financial_statement_text
      <<~TXT.squish
        We’ve updated the financial statements from June 2025 onwards to reflect
        changes to the payment schedules. We’ve split out ECT and mentor output
        payments, removed uplift fees, and deleted Band D from the ECT payment
        bands.
      TXT
    end
  end
end
