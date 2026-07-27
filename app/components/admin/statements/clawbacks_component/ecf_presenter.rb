module Admin
  module Statements
    class ClawbacksComponent < ApplicationComponent
      class ECFPresenter < BandedPresenter
        def caption_text = "Clawbacks"

        def rows
          super + [uplift_row].compact
        end

        def total_refundable_amount
          super + uplifts.total_refundable_amount
        end

      private

        def uplift_row
          return unless uplifts.refundable_count.positive?

          Row.new(
            payment_type: "Uplift",
            refundable_count: uplifts.refundable_count,
            fee_per_declaration: uplifts.uplift_fee_per_declaration,
            total_refundable_amount: uplifts.total_refundable_amount
          )
        end
      end
    end
  end
end
