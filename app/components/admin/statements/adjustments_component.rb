module Admin
  module Statements
    class AdjustmentsComponent < ApplicationComponent
      delegate :number_to_pounds, to: :helpers

      delegate :adjustment_editable?,
               to: :statement

      attr_accessor :statement

      def initialize(statement:)
        @statement = statement
      end

      def adjustments
        statement.adjustments.order(created_at: :asc)
      end

      def change_or_remove_link(adjustment)
        return unless adjustment_editable?

        change_link(adjustment) + " | " + remove_link(adjustment)
      end

      def change_link(adjustment)
        return unless adjustment_editable?

        govuk_link_to("Change", edit_admin_finance_statement_adjustment_path(statement, adjustment))
      end

      def remove_link(adjustment)
        return unless adjustment_editable?
        
        govuk_link_to("Remove", delete_admin_finance_statement_adjustment_path(statement, adjustment))
      end

      def total
        safe_join([
          tag.div("Total", class: "govuk-!-text-align-right govuk-heading-s govuk-!-margin-bottom-0"),
          tag.div(number_to_pounds(total_amount), class: "govuk-!-text-align-right govuk-heading-s")
        ])
      end

      def add_adjustment_link
        tag.p do
          govuk_link_to(
            "Add",
            new_admin_finance_statement_adjustment_path(statement),
            visually_hidden_suffix: "adjustment"
          )
        end
      end

    private

      def total_amount
        adjustments.sum(&:amount)
      end

      
    end
  end
end
