module Admin
  module Statements
    module PaymentOverview
      class ECFComponent < PaymentOverviewComponent
        def rows
          [
            ["Output payment", { text: number_to_pounds(outputs), numeric: true }],
            ["Service fee", { text: number_to_pounds(monthly_service_fee), numeric: true }],
            ["Uplift fees", { text: number_to_pounds(uplift_fees), numeric: true }],
            ["Clawbacks", { text: number_to_pounds(clawbacks), numeric: true }],
            ["Additional adjustments", { text: number_to_pounds(total_manual_adjustments_amount), numeric: true }],
            ["VAT", { text: number_to_pounds(vat_amount), numeric: true }]
          ]
        end

      private

        def uplift_fees
          banded_calculator.uplifts.total_billable_amount
        end

        def clawbacks
          -(banded_calculator.outputs.total_refundable_amount + banded_calculator.uplifts.total_refundable_amount)
        end
      end
    end
  end
end
