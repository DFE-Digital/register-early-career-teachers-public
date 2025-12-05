module Statements
  class Search
    class InvalidFeeTypeError < StandardError; end

    include Queries::FilterIgnorable

    attr_reader :scope

    def initialize(lead_provider_id: :ignore,
                   contract_period_years: :ignore,
                   fee_type: "output",
                   statement_date: :ignore,
                   deadline_date: :ignore,
                   order: :payment_date)
      @scope = Statement.distinct.includes(active_lead_provider: %i[lead_provider contract_period])

      where_lead_provider_is(lead_provider_id)
      where_contract_period_year_in(contract_period_years)
      where_fee_type_is(fee_type)
      where_statement_date(statement_date)
      where_deadline_date(deadline_date)
      set_order(order)
    end

    def statements
      scope
    end

  private

    def where_lead_provider_is(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      @scope = scope.joins(:lead_provider).where(lead_providers: { id: lead_provider_id })
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years)

      @scope = scope.joins(:contract_period).where(contract_periods: { year: contract_period_years })
    end

    def where_fee_type_is(fee_type)
      return if ignore?(filter: fee_type)

      fail InvalidFeeTypeError unless fee_type.in?(Statement::VALID_FEE_TYPES)

      @scope = scope.with_fee_type(fee_type)
    end

    def where_statement_date(statement_date)
      return if ignore?(filter: statement_date)
      return if statement_date.blank?

      year, month = statement_date.split("-").map(&:to_i) # 2025-01 -> 2025 & 1
      @scope = scope.with_statement_date(year:, month:)
    end

    def where_deadline_date(deadline_date)
      return if ignore?(filter: deadline_date)
      return if deadline_date.blank?

      @scope = scope.where(deadline_date:)
    end

    def set_order(order)
      return if ignore?(filter: order)

      case order
      when :statement_date
        @scope = scope.order(year: :asc, month: :asc)
      when :payment_date
        @scope = scope.order(payment_date: :asc)
      when :deadline_date
        @scope = scope.order(deadline_date: :asc)
      end
    end
  end
end
