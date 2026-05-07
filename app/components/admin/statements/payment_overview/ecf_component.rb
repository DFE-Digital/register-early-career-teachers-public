module Admin
  module Statements
    module PaymentOverview
      class ECFComponent < PaymentOverviewComponent
        def rows
          [
            ["Output payment", { text: number_to_pounds(outputs), numeric: true }],
            ["Service fee", { text: number_to_pounds(monthly_service_fee), numeric: true }],
            ["Uplift fees", { text: number_to_pounds(uplifts), numeric: true }],
            ["Clawbacks", { text: number_to_pounds(clawbacks), numeric: true }],
            ["Additional adjustments", { text: number_to_pounds(total_manual_adjustments_amount), numeric: true }],
            ["VAT", { text: number_to_pounds(vat_amount), numeric: true }]
          ]
        end

      private

        def uplifts
          raise ArgumentError, "Expected exactly 1 calculator for ECF contract type" unless calculators.one?
          raise ArgumentError, "Expected Banded calculator for ECF contract type" unless banded

          @uplifts ||= banded.uplifts.total_billable_amount
        end

        def clawbacks
          @clawbacks ||= -(banded.outputs.total_refundable_amount + banded.uplifts.total_refundable_amount)
        end
      end
    end
  end
end
