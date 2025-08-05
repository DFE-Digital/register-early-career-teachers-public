module Schools
  class Query
    include Queries::ConditionFormats
    include FilterIgnorable
    include QueryOrderable

    attr_reader :sort, :contract_period_id, :urn, :updated_since, :lead_provider_id, :scope

    def initialize(lead_provider_id: :ignore, urn: :ignore, updated_since: :ignore, contract_period_id: :ignore, sort: nil)
      @lead_provider_id = lead_provider_id
      @contract_period_id = contract_period_id
      @sort = sort
      @urn = urn
      @updated_since = updated_since
      @scope = default_scope(contract_period_id)
               .or(schools_with_existing_partnerships(contract_period_id))
               .distinct
    end

    def schools_for_pagination
      where_urn_is(urn)
      where_updated_since(updated_since)

      scope
      .select("schools.id", "schools.urn", "schools.created_at", "schools.updated_at")
      .order(order_by)
    end

    def schools_from(paginated_join)
      School.select(*select_fields)
      .where(schools: { id: paginated_join.map(&:id) })
      .eager_load(:gias_school)
      .order(order_by)
      .distinct
    end

    def school_by_api_id(api_id)
      return scope.select(*select_fields).find_by!(gias_school: { api_id: }) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def school(id)
      return scope.select(*select_fields).find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def select_fields
      [
        "schools.*",
        transient_lead_provider_contract_period(contract_period_id, lead_provider_id),
        "'#{contract_period_id}' AS transient_contract_period_id",
        "'#{lead_provider_id}' AS transient_lead_provider_id"
      ]
    end

    def schools_with_existing_partnerships(contract_period_id)
      School.where(id: School.select("schools.id")
        .joins(school_partnerships: { lead_provider_delivery_partnership: { active_lead_provider: :contract_period } })
        .where(contract_periods: { year: contract_period_id }))
    end

    def where_urn_is(urn)
      return if ignore?(filter: urn)

      scope.merge!(School.where(urn:))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      scope.merge!(School.where(updated_at: updated_since..))
    end

    def transient_lead_provider_contract_period(contract_period_id, lead_provider_id)
      <<~SQL
        (
          SELECT ARRAY[slpcp.in_partnership::text, slpcp.training_programme::text, slpcp.expression_of_interest::text] AS transient_lead_provider_contract_period
          FROM schools_lead_providers_contract_periods slpcp
          WHERE slpcp.school_id = schools.id
          AND slpcp.contract_period_id = #{contract_period_id}
          AND slpcp.lead_provider_id = #{lead_provider_id}
        )
      SQL
    end

    def default_scope(contract_period_id)
      return School.none if ignore?(filter: contract_period_id) ||
        contract_period_id.blank? ||
        ContractPeriod.find_by(year: contract_period_id).blank?

      School
        .eligible
        .not_cip_only
    end

    def order_by
      sort_order(sort:, model: School, default: { created_at: :asc })
    end
  end
end
