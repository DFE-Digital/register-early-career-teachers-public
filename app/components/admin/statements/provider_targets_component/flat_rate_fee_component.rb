module Admin::Statements
  class ProviderTargetsComponent::FlatRateFeeComponent < ApplicationComponent
    def initialize(contract:)
      @contract = contract
    end

    def render? = flat_rate_fee_structure.present?

    erb_template <<~ERB
      <%=
        govuk_summary_list do |summary_list|
          summary_list.with_row do |row|
            row.with_key(text: "Mentors recruitment target")
            row.with_value(text: recruitment_target)
          end

          summary_list.with_row do |row|
            row.with_key(text: "Payment per participant")
            row.with_value(text: number_to_pounds(payment_per_participant))
          end
        end
      %>
    ERB

  private

    attr_reader :contract

    delegate :flat_rate_fee_structure, to: :contract, private: true
    delegate :number_to_pounds, :number_to_percentage, to: :helpers

    def recruitment_target = flat_rate_fee_structure.recruitment_target
    def payment_per_participant = flat_rate_fee_structure.fee_per_declaration
  end
end
