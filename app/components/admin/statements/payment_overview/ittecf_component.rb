module Admin
  module Statements
    module PaymentOverview
      class IttecfComponent < PaymentOverviewComponent
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

        def flat_rate
          @flat_rate ||= calculators.first
        end

        def flat_rate_total
          @flat_rate_total ||= flat_rate.total_amount(with_vat: true)
        end

        def flat_rate_vat
          @flat_rate_vat ||= flat_rate.vat_amount
        end

        def mentors_outputs
          @mentors_outputs ||= flat_rate.outputs.total_net_amount
        end

        def mentors_clawbacks
          @mentors_clawbacks ||= flat_rate.outputs.total_refundable_amount
        end

        def total_amount
          banded_total + flat_rate_total
        end

        def vat_amount
          banded_vat + flat_rate_vat
        end
      end
    end
  end
end
