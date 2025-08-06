module Admin
  module Statements
    class SelectorComponent < ViewComponent::Base
      def initialize(statement:)
        @statement = statement
      end

      def lead_providers
        LeadProvider.alphabetical
      end

      def lead_provider_id
        @statement.active_lead_provider.lead_provider_id
      end

      def contract_periods
        ContractPeriod.order(year: :asc)
      end

      def contract_period_year
        @statement.active_lead_provider.contract_period_year
      end

      def statement_dates
        statement_date = Struct.new(:id, :name, keyword_init: true)
        dates = Statement.order(:year, :month).pluck(:year, :month).uniq

        dates.map do |date|
          statement_date.new(
            name: ::Statements::Period.from_year_and_month(date.first, date.second), # January 2025
            id: date.join("-") # 2025-01
          )
        end
      end

      def statement_date
        [@statement.year, @statement.month].join("-")
      end
    end
  end
end
