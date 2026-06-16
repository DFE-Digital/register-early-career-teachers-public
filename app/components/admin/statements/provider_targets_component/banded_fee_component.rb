module Admin::Statements
  class ProviderTargetsComponent::BandedFeeComponent < ApplicationComponent
    REVISED_RECRUITMENT_TARGET_MULTIPLIER = 1.5

    def initialize(contract:)
      @contract = contract
    end

    def render? = banded_fee_structure.present?

    erb_template <<~ERB
      <%=
        govuk_summary_list do |summary_list|
          summary_list.with_row do |row|
            row.with_key(text: recruitment_target_label)
            row.with_value(text: recruitment_target)
          end

          summary_list.with_row do |row|
            row.with_key(text: revisted_recruitment_target_label)
            row.with_value(text: (recruitment_target * REVISED_RECRUITMENT_TARGET_MULTIPLIER).to_i)
          end

          if display_uplifts?
            summary_list.with_row do |row|
              row.with_key(text: "Uplift target")
              row.with_value(text: number_to_percentage(uplift_target_percentage, precision: 0))
            end

            summary_list.with_row do |row|
              row.with_key(text: "Uplift amount")
              row.with_value(text: number_to_pounds(uplift_amount))
            end
          end

          summary_list.with_row do |row|
            row.with_key(text: "Setup fee")
            row.with_value(text: number_to_pounds(setup_fee))
          end
        end
      %>

      <%=
        govuk_table do |table|
          table.with_caption(text: "Contract bands", classes: "govuk-visually-hidden")

          table.with_head do |head|
            head.with_row do |row|
              row.with_cell(header: true) { "Band" }
              row.with_cell(header: true, numeric: true, text: "Min")
              row.with_cell(header: true, numeric: true, text: "Max")
              row.with_cell(header: true, numeric: true, text: "Fee per declaration")
            end
          end

          table.with_body do |body|
            band_terms.each do |band_term|
              body.with_row do |row|
                row.with_cell { band_term_label(band_term) }
                row.with_cell(numeric: true, text: band_term.min_declarations)
                row.with_cell(numeric: true, text: band_term.max_declarations)
                row.with_cell(numeric: true, text: number_to_pounds(band_term.fee_per_declaration))
              end
            end
          end
        end
      %>
    ERB

  private

    attr_reader :contract

    delegate :banded_fee_structure, to: :contract, private: true

    delegate :number_to_pounds, :number_to_percentage, to: :helpers

    delegate :recruitment_target,
             :setup_fee,
             :band_terms,
             to: :banded_fee_structure

    def recruitment_target_label
      if contract.ecf_contract_type?
        "Recruitment target"
      else
        "ECTs recruitment target"
      end
    end

    def revisted_recruitment_target_label
      "Revised recruitment target " \
      "(#{number_to_percentage(REVISED_RECRUITMENT_TARGET_MULTIPLIER * 100, precision: 0)})"
    end

    def display_uplifts? = contract.ecf_contract_type? && uplift_target_ratio.present?
    def uplift_target_ratio = banded_fee_structure.uplift_target_ratio
    def uplift_target_percentage = uplift_target_ratio * 100
    def uplift_amount = banded_fee_structure.uplift_fee_per_declaration

    def band_term_label(band_term) = "Band #{band_term.letter}"
  end
end
