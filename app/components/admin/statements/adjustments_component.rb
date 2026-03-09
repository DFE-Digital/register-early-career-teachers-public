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

      def total_amount
        adjustments.sum(&:amount)
      end

      def adjustments
        statement.adjustments.order(created_at: :asc)
      end

      def change_or_remove_links(adjustment)
        return unless adjustment_editable?

        change_link(adjustment)  + " | " + remove_link(adjustment)
      end


      def change_link(adjustment)
        govuk_link_to("Change", edit_admin_finance_statement_adjustment_path(statement, adjustment))
      end

      def remove_link(adjustment)
        govuk_link_to("Remove", delete_admin_finance_statement_adjustment_path(statement, adjustment))
      end
    end
  end
end
