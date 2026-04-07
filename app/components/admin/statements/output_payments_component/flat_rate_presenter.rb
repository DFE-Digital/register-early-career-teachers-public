module Admin
  module Statements
    class OutputPaymentsComponent < ApplicationComponent
      class FlatRatePresenter < BasePresenter
        def caption_text = "Mentor output payments"
        def total_label = "Mentors output payment total"
        def fee_label = "Fee per mentor"
        def columns = %w[Participants]

        def row_pairs
          declaration_type_outputs.map do |output|
            [
              [
                output.declaration_type.underscore.humanize,
                output.billable_count.to_s,
                nil
              ],
              [
                fee_label,
                output.type_adjusted_fee_per_declaration,
                output.total_billable_amount
              ]
            ]
          end
        end
      end
    end
  end
end
