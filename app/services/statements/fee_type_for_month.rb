module Statements
  class FeeTypeForMonth
    OUTPUT_FEE_MONTHS = %w[January April August November].freeze

    def initialize(month:)
      @month = month
    end

    def call
      if @month.present?
        Date::MONTHNAMES[@month].in?(OUTPUT_FEE_MONTHS) ? "output" : "service"
      end
    end
  end
end
