module Statements
  class FeeTypeForMonth
    OUTPUT_FEE_MONTHS = %w[January April August November].freeze

    def initialize(month:)
      @month = month
    end

    def call
      return if month.blank?

      output_fee_type_month? ? "output" : "service"
    end

  private

    attr_accessor :month

    def output_fee_type_month?
      Date::MONTHNAMES[month].in?(OUTPUT_FEE_MONTHS)
    end
  end
end
