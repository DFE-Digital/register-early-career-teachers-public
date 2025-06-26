module Statements
  class Query
    include Queries::ConditionFormats
    include FilterIgnorable

    attr_reader :scope

    def initialize(lead_provider: :ignore, registration_period_years: :ignore, updated_since: :ignore, status: :ignore, output_fee: true, statement_date: :ignore, order_by: :payment_date)
      @scope = Statement.distinct.includes(active_lead_provider: %i[lead_provider registration_period])

      where_lead_provider_is(lead_provider)
      where_registration_period_year_in(registration_period_years)
      where_updated_since(updated_since)
      where_status_is(status)
      where_output_fee_is(output_fee)
      where_statement_date(statement_date)
      set_order_by(order_by)
    end

    def statements
      scope
    end

    def statement_by_api_id(api_id)
      return scope.find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def statement(id)
      return scope.find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def where_lead_provider_is(lead_provider)
      return if ignore?(filter: lead_provider)

      scope.merge!(Statement.joins(:lead_provider).where(lead_providers: { id: lead_provider.id }))
    end

    def where_registration_period_year_in(registration_period_years)
      return if ignore?(filter: registration_period_years)

      scope.merge!(Statement.joins(:registration_period).where(registration_periods: { year: extract_conditions(registration_period_years) }))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      scope.merge!(Statement.where(updated_at: updated_since..))
    end

    def where_status_is(state)
      return if ignore?(filter: state)

      scope.merge!(Statement.with_status(extract_conditions(state)))
    end

    def where_output_fee_is(output_fee)
      return if ignore?(filter: output_fee)

      scope.merge!(Statement.with_output_fee(output_fee:))
    end

    def where_statement_date(statement_date)
      return if ignore?(filter: statement_date)
      return if statement_date.blank?

      year, month = statement_date.split("-").map(&:to_i) # 2025-01 -> 2025 & 1
      scope.merge!(Statement.with_statement_date(year:, month:))
    end

    def set_order_by(order_by)
      return if ignore?(filter: order_by)

      case order_by
      when :statement_date
        scope.merge!(Statement.order(year: :asc, month: :asc))
      when :payment_date
        scope.merge!(Statement.order(payment_date: :asc))
      end
    end
  end
end
