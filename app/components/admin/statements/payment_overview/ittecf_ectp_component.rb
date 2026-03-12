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

        def flat_rate
          @flat_rate ||= flat_rate_calculator
        end

        def flat_rate_calculator
          raise ArgumentError, "Expected exactly 2 calculators for ECF contract type" unless calculators.count == 2

          flat_rate_calculator = calculators.find { |c| c.is_a? PaymentCalculator::FlatRate }

          raise ArgumentError, "Expected flat rate calculator for IITECF ECTP contract type" unless flat_rate_calculator

          flat_rate_calculator
        end

        def mentors_outputs
          @mentors_outputs ||= flat_rate.outputs.total_net_amount
        end

        def mentors_clawbacks
          @mentors_clawbacks ||= flat_rate.outputs.total_refundable_amount
        end
      end
    end
  end
end
