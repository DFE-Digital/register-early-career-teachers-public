module Admin::Statements
  class ProviderTargetsComponent::BandedFeeComponent < ApplicationComponent
    REVISED_RECRUITMENT_TARGET_MULTIPLIER = 1.5
    UPLIFT_TARGET_PERCENTAGE = 33

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
              row.with_value(text: number_to_percentage(UPLIFT_TARGET_PERCENTAGE, precision: 0))
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
              row.with_cell(header: true, numeric: true, text: "Payment amount per participant")
            end
          end

          table.with_body do |body|
            bands.each_with_index do |band, index|
              body.with_row do |row|
                row.with_cell { band_label(index) }
                row.with_cell(numeric: true, text: band.min_declarations)
                row.with_cell(numeric: true, text: band.max_declarations)
                row.with_cell(numeric: true, text: number_to_pounds(band.fee_per_declaration))
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

    def recruitment_target = banded_fee_structure.recruitment_target
    def display_uplifts? = contract.ecf_contract_type?
    def uplift_amount = banded_fee_structure.uplift_fee_per_declaration
    def setup_fee = banded_fee_structure.setup_fee
    def bands = banded_fee_structure.bands

    def band_label(index)
      letter = ("A"..."Z").to_a[index]
      "Band #{letter}"
    end
  end
end
