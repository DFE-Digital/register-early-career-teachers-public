module Statements
  class FeeTypeForMonth
    OUTPUT_FEE_MONTHS = [
      1,  # January
      4,  # April
      8,  # August
      11, # November
    ].freeze

    def initialize(month:)
      @month = month
    end

    def call
      return if month.blank?

      month.in?(OUTPUT_FEE_MONTHS) ? "output" : "service"
    end

  private

    attr_reader :month
  end
end
