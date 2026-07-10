module Admin
  module Statements
    class ClawbacksComponent < ApplicationComponent
      class BasePresenter < SimpleDelegator
        Row = Data.define(:payment_type, :refundable_count, :fee_per_declaration, :total_refundable_amount)

        delegate :total_refundable_amount,
                 :declaration_type_outputs,
                 to: :outputs

        def rows
          refundable_outputs.map do |output|
            Row.new(
              payment_type: payment_type(output),
              refundable_count: output.refundable_count,
              fee_per_declaration: output.type_adjusted_fee_per_declaration,
              total_refundable_amount: output.total_refundable_amount
            )
          end
        end

      private

        def refundable_outputs
          declaration_type_outputs.select { it.refundable_count.positive? }
        end

        def payment_type(output)
          output.declaration_type.humanize
        end
      end
    end
  end
end
