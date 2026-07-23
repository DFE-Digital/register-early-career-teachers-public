module Admin
  module Statements
    module PaymentOverview
      class IttecfEctpComponent < PaymentOverviewComponent
        def rows
          [
            ["ECTs output payment", { text: number_to_pounds(outputs), numeric: true }],
            ["Mentors output payment", { text: number_to_pounds(mentors_outputs), numeric: true }],
            ["Service fee", { text: number_to_pounds(monthly_service_fee), numeric: true }],
            ["ECTs clawbacks", { text: number_to_pounds(clawbacks), numeric: true }],
            ["Mentors clawbacks", { text: number_to_pounds(mentors_clawbacks), numeric: true }],
            ["Additional adjustments", { text: number_to_pounds(total_manual_adjustments_amount), numeric: true }],
            ["VAT", { text: number_to_pounds(vat_amount), numeric: true }]
          ]
        end

      private

        delegate :flat_rate_calculator, to: :calculators, private: true

        def mentors_outputs
          flat_rate_calculator.outputs.total_billable_amount
        end

        def mentors_clawbacks
          -flat_rate_calculator.outputs.total_refundable_amount
        end
      end
    end
  end
end
