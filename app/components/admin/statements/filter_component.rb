module Admin
  module Statements
    class FilterComponent < ViewComponent::Base
      attr_reader :params

      def initialize(filter_params:)
        @params = filter_params
      end

      def lead_providers
        LeadProvider.alphabetical
      end

      def lead_provider_id
        params[:lead_provider_id]
      end

      def contract_periods
        ContractPeriod.order(year: :asc)
      end

      def contract_period_id
        params[:contract_period_id]
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
        params[:statement_date]
      end

      def statement_types
        statement_type = Struct.new(:id, :name, keyword_init: true)
        [
          statement_type.new(name: "All", id: "all"),
          statement_type.new(name: "Output statements", id: "output_fee"),
          statement_type.new(name: "Service fee statements", id: "service_fee"),
        ]
      end

      def statement_type
        params[:statement_type].presence || "output_fee"
      end

    private

      def month_name(month)
        Date::MONTHNAMES.fetch(month)
      end
    end
  end
end
