module Statements
  class Query
    class InvalidFeeTypeError < StandardError; end

    include Queries::ConditionFormats
    include Queries::FilterIgnorable
    include Queries::Orderable
    include Queries::AssociationPreloadable

    attr_reader :scope

    def initialize(lead_provider_id: :ignore, contract_period_years: :ignore, updated_since: :ignore, status: :ignore, fee_type: 'output', statement_date: :ignore, sort: nil)
      @scope = Statement.distinct

      where_lead_provider_is(lead_provider_id)
      where_contract_period_year_in(contract_period_years)
      where_updated_since(updated_since)
      where_status_is(status)
      where_fee_type_is(fee_type)
      where_statement_date(statement_date)
      set_sort_by(sort)
    end

    def statements
      preload_associations(block_given? ? yield(scope) : scope)
    end

    def statement_by_api_id(api_id)
      return preload_associations(scope).find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def statement_by_id(id)
      return preload_associations(scope).find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def where_lead_provider_is(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      @scope = scope.joins(:lead_provider).where(lead_providers: { id: lead_provider_id })
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years)

      @scope = scope.joins(:active_lead_provider).where(active_lead_provider: { contract_period_year: extract_conditions(contract_period_years) })
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      @scope = scope.where(updated_at: updated_since..)
    end

    def where_status_is(state)
      return if ignore?(filter: state)

      @scope = scope.with_status(extract_conditions(state))
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

    def set_sort_by(sort)
      @scope = scope.order(sort_order(sort:, model: Statement, default: { payment_date: :asc }))
    end
  end
end
