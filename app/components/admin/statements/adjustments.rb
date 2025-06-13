module Admin
  module Statements
    class Adjustments < ViewComponent::Base
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
    end
  end
end
