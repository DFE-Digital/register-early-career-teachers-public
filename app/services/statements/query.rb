module Statements
  class Query
    include Queries::ConditionFormats
    include FilterIgnorable

    attr_reader :scope

    def initialize(lead_provider: :ignore, registration_period_years: :ignore, updated_since: :ignore, state: :ignore, output_fee: true)
      @scope = Statement.distinct.includes(active_lead_provider: %i[lead_provider registration_period])

      where_lead_provider_is(lead_provider)
      where_registration_period_year_in(registration_period_years)
      where_updated_since(updated_since)
      where_state_is(state)
      where_output_fee_is(output_fee)
    end

    def statements
      scope.order(payment_date: :asc)
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

    def where_state_is(state)
      return if ignore?(filter: state)

      scope.merge!(Statement.with_state(extract_conditions(state)))
    end

    def where_output_fee_is(output_fee)
      return if ignore?(filter: output_fee)

      scope.merge!(Statement.with_output_fee(output_fee:))
    end
  end
end
