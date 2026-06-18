module Admin
  module Statements
    class OutputPaymentsComponent < ApplicationComponent
      class BandedPresenter < BasePresenter
        def caption_text = "Early career teacher (ECT) output payments"
        def total_label = "ECTs output payment total"
        def fee_label = "Fee per ECT"
        def columns = terms.map { "Band #{it.letter}" }

        def row_pairs
          grouped_outputs.map { |display_type, outputs| row_pair(display_type, outputs) }
        end

      private

        delegate :terms, to: :banded_fee_structure

        def row_pair(display_type, outputs)
          by_term = outputs.group_by(&:term)
          counts  = terms.map { |b| by_term[b].sum(&:billable_count).to_s }
          fees    = terms.map { |b| by_term[b].first.type_adjusted_fee_per_declaration }

          [
            [
              display_type.underscore.humanize,
              *counts,
              nil
            ],
            [
              fee_label,
              *fees,
              outputs.sum(&:total_billable_amount)
            ]
          ]
        end

        # @return [Hash{String => Array<PaymentCalculator::Banded::DeclarationTypeOutput>}]
        def grouped_outputs
          declaration_type_outputs.group_by do |output|
            output.declaration_type.start_with?("extended") ? "extended" : output.declaration_type
          end
        end
      end
    end
  end
end
