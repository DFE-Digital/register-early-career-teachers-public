module Admin
  module Statements
    class PaymentOverviewComponent < ApplicationComponent
      def initialize(statement:)
        @statement = statement
      end

      

      def rows
        # TODO
        # needs to switch between pre-post 2025 layout
      end

      # Common Elements
      def total_payment_text
        "Total £#{3000.56}"
      end

      private

      def pre_or_post_2025?
      end

      def total_payment
      end

      def vat
      end

      def adjustments
        # TODO: this is a summed amount so could come from the adjustments component
      end

      def service_fee
      end

      # PRE 2025
      def output_payment
      end

      def clawbacks
      end

      def uplift_fees
      end

      # POST 2025
      def ects_output_payment 
      end

      def mentors_output_payment
      end

      def ects_clawbacks
      end

      def mentors_clawbacks
      end

    end
  end
end
