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

      def contract_period_id
        @statement.active_lead_provider.contract_period_id
      end

      def statement_dates
        statement_date = Struct.new(:id, :name, keyword_init: true)
        dates = Statement.order(:year, :month).pluck(:year, :month).uniq

        dates.map do |date|
          statement_date.new(
            name: "#{month_name(date[1])} #{date[0]}", # January 2025
            id: date.join("-") # 2025-01
          )
        end
      end

      def statement_date
        [@statement.year, @statement.month].join("-")
      end

    private

      def month_name(month)
        Date::MONTHNAMES.fetch(month)
      end
    end
  end
end
