module API::Statements
  class Query
    class InvalidFeeTypeError < StandardError; end

    include Queries::ConditionFormats
    include Queries::FilterIgnorable
    include Queries::Orderable

    attr_reader :scope

    def initialize(lead_provider_id: :ignore, contract_period_years: :ignore, updated_since: :ignore, fee_type: 'output', sort: nil)
      @scope = Statement.distinct.includes(active_lead_provider: %i[lead_provider contract_period])

      where_lead_provider_is(lead_provider_id)
      where_contract_period_year_in(contract_period_years)
      where_updated_since(updated_since)
      where_fee_type_is(fee_type)
      set_sort_by(sort)
    end

    def statements
      scope
    end

    def statement_by_api_id(api_id)
      return scope.find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def statement_by_id(id)
      return scope.find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def where_lead_provider_is(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      scope.merge!(Statement.joins(:lead_provider).where(lead_providers: { id: lead_provider_id }))
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years)

      scope.merge!(Statement.joins(:contract_period).where(contract_periods: { year: extract_conditions(contract_period_years) }))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      scope.merge!(Statement.where(updated_at: updated_since..))
    end

    def where_fee_type_is(fee_type)
      return if ignore?(filter: fee_type)

      fail InvalidFeeTypeError unless fee_type.in?(Statement::VALID_FEE_TYPES)

      scope.merge!(Statement.with_fee_type(fee_type))
    end

    def set_sort_by(sort)
      @scope = scope.order(sort_order(sort:, model: Statement, default: { payment_date: :asc }))
    end
  end
end
