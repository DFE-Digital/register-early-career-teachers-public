module API::Schools
  class Query
    include Queries::ConditionFormats
    include Queries::FilterIgnorable
    include Queries::Orderable

    attr_reader :scope, :sort

    def initialize(lead_provider_id: :ignore, urn: :ignore, updated_since: :ignore, contract_period_year: :ignore, sort: nil)
      @scope = default_scope(contract_period_year)
        .or(schools_with_existing_partnerships(contract_period_year))
        .includes(:contract_period_metadata, :lead_provider_contract_period_metadata)
        .distinct

      where_metadata_belongs_to_lead_provider(lead_provider_id)
      where_metadata_belongs_to_contract_period(contract_period_year)
      where_urn_is(urn)
      where_updated_since(updated_since)
      set_sort_by(sort)
    end

    def schools
      scope
    end

    def school_by_api_id(api_id)
      return scope.find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def school_by_id(id)
      return scope.find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def where_metadata_belongs_to_lead_provider(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      @scope = scope
        .references(:metadata_schools_lead_providers_contract_periods)
        .where('metadata_schools_lead_providers_contract_periods.lead_provider_id' => [lead_provider_id, nil])
    end

    def where_metadata_belongs_to_contract_period(contract_period_year)
      return if ignore?(filter: contract_period_year)

      @scope = scope
        .references(:metadata_schools_contract_periods, :metadata_schools_lead_providers_contract_periods)
        .where('metadata_schools_contract_periods.contract_period_year' => [contract_period_year, nil])
        .where('metadata_schools_lead_providers_contract_periods.contract_period_year' => [contract_period_year, nil])
    end

    def schools_with_existing_partnerships(contract_period_year)
      School.where(id: School.select("schools.id")
        .joins(school_partnerships: { lead_provider_delivery_partnership: { active_lead_provider: :contract_period } })
        .where(contract_periods: { year: contract_period_year }))
    end

    def where_urn_is(urn)
      return if ignore?(filter: urn)

      scope.merge!(School.where(urn:))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      scope.merge!(School.where(updated_at: updated_since..))
    end

    def default_scope(contract_period_year)
      return School.none if ignore?(filter: contract_period_year) || ContractPeriod.find_by(year: contract_period_year).blank?

      School
        .eligible
        .not_cip_only
        .eager_load(:gias_school)
    end

    def set_sort_by(sort)
      @scope = scope.order(sort_order(sort:, model: School, default: { created_at: :asc }))
    end
  end
end
