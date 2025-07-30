module Schools
  class Query
    include Queries::ConditionFormats
    include FilterIgnorable
    include QueryOrderable

    attr_reader :scope, :sort

    def initialize(lead_provider_id: :ignore, urn: :ignore, updated_since: :ignore, contract_period_id: :ignore, sort: nil)
      @scope = default_scope(contract_period_id, lead_provider_id).select(
        "schools.*",
        transient_lead_provider_contract_period(contract_period_id, lead_provider_id),
        "'#{contract_period_id}' AS transient_contract_period_id",
        "'#{lead_provider_id}' AS transient_lead_provider_id"
      ).or(schools_with_existing_partnerships(contract_period_id))
        .distinct

      @sort = sort

      where_urn_is(urn)
      where_updated_since(updated_since)
    end

    def schools
      scope.order(order_by)
    end

    def school_by_api_id(api_id)
      return scope.find_by!(gias_school: { api_id: }) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def school(id)
      return scope.find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

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

    def schools_with_existing_partnerships(contract_period_id)
      School.where(id: School.select("schools.id")
         .joins(:lead_provider_contract_periods)
         .where(lead_provider_contract_periods: { contract_period_id:, in_partnership: true }))
    end

    def where_urn_is(urn)
      return if ignore?(filter: urn)

      scope.merge!(School.where(urn:))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      scope.merge!(School.where(updated_at: updated_since..))
    end

    def default_scope(contract_period_id, lead_provider_id)
      return School.none if ignore?(filter: contract_period_id) ||
        contract_period_id.blank? ||
        ContractPeriod.find_by(year: contract_period_id).blank?

      School
        .eligible
        .not_cip_only
        .eager_load(:gias_school, :lead_provider_contract_periods)
    end

    def order_by
      sort_order(sort:, model: School, default: { created_at: :asc })
    end
  end
end
