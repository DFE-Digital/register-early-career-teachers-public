module Admin::Statements
  class ProviderTargetsComponent < ApplicationComponent
    def initialize(statement:)
      @statement = statement
    end

    erb_template <<~ERB
      <%= govuk_details(summary_text: "Provider targets (per academic year)") do %>
          <%= govuk_summary_list do |summary_list|
            summary_list.with_row do |row|
              row.with_key { "Provider" }
              row.with_value { lead_provider.name }
            end
          end %>

          <%= render BandedFeeComponent.new(contract:) %>
          <%= render FlatRateFeeComponent.new(contract:) %>
      <% end %>
    ERB

  private

    attr_reader :statement

    delegate :contract, :lead_provider, to: :statement, private: true
  end
end
