module Admin
  module Statements
    class OutputPaymentsComponent < ApplicationComponent
      class BandedPresenter < BasePresenter
        def caption_text = "Early career teacher (ECT) output payments"
        def total_label = "ECTs output payment total"
        def fee_label = "Fee per ECT"
        def columns = band_terms.map { "Band #{it.letter}" }

        def row_pairs
          grouped_outputs.map { |display_type, outputs| row_pair(display_type, outputs) }
        end

      private

        delegate :band_terms, to: :banded_fee_structure

        def row_pair(display_type, outputs)
          by_band_term = outputs.group_by(&:band_term)
          counts  = band_terms.map { |bt| by_band_term[bt].sum(&:billable_count).to_s }
          fees    = band_terms.map { |bt| by_band_term[bt].first.type_adjusted_fee_per_declaration }

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
