module Admin
  module Statements
    class PaymentAuthorisationComponent < ViewComponent::Base
      delegate :can_authorise_payment?,
               to: :statement

      attr_accessor :statement

      def initialize(statement:)
        @statement = statement
      end

      def render?
        statement.output_fee
      end

      def marked_as_paid?
        statement.marked_as_paid_at.present?
      end

      def marked_as_paid_text
        "Authorised for payment at #{marked_as_paid_at}"
      end

      def marked_as_paid_at
        statement.marked_as_paid_at.in_time_zone("London").strftime("%-I:%M%P on %-e %b %Y")
      end
    end
  end
end
