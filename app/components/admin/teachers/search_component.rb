module Admin
  module Teachers
    class SearchComponent < ApplicationComponent
      FilterOption = Data.define(:value, :name)

      attr_reader :filter_params, :form_url

      def initialize(form_url:, filter_params:)
        @form_url = form_url
        @filter_params = filter_params
      end

    private

      def role_filter_options
        Rows::ROLE_NAMES.map do |value, name|
          FilterOption.new(value:, name:)
        end
      end

      def contract_period_filter_options
        filter_options = ContractPeriod.order(:year).map do |contract_period|
          year = contract_period.year.to_s

          FilterOption.new(value: year, name: year)
        end

        filter_options + [
          FilterOption.new(
            value: Rows::CONTRACT_PERIOD_NOT_AVAILABLE,
            name: "Not available"
          )
        ]
      end
    end
  end
end
