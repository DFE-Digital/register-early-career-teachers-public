module API::Schools
  class Query
    include Queries::FilterIgnorable

    attr_reader :scope, :sort, :lead_provider_id, :contract_period_year

    def initialize(contract_period_year:, lead_provider_id: :ignore, urn: :ignore, updated_since: :ignore, sort: { created_at: :asc })
      @lead_provider_id = lead_provider_id
      @contract_period_year = contract_period_year
      @scope = School.eligible.not_cip_only

      or_where_school_partnership_exists(contract_period_year)
      where_contract_period_exists(contract_period_year)
      where_urn_is(urn)
      where_updated_since(updated_since)
      set_sort_by(sort)
    end

    def schools
      preload_associations(block_given? ? yield(scope) : scope)
    end

    def school_by_api_id(api_id)
      return preload_associations(scope).find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def school_by_id(id)
      return preload_associations(scope).find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def preload_associations(results)
      preloaded_results = results
        .strict_loading
        .includes(:gias_school, :contract_period_metadata, :lead_provider_contract_period_metadata)

      unless ignore?(filter: lead_provider_id)
        preloaded_results = preloaded_results
          .references(:metadata_schools_lead_providers_contract_periods)
          .where(metadata_schools_lead_providers_contract_periods: { lead_provider_id: })
      end

      unless ignore?(filter: contract_period_year)
        preloaded_results = preloaded_results
          .references(:metadata_schools_contract_periods, :metadata_schools_lead_providers_contract_periods)
          .where(metadata_schools_contract_periods: { contract_period_year: }, metadata_schools_lead_providers_contract_periods: { contract_period_year: })
      end

      preloaded_results
    end

    def where_contract_period_exists(contract_period_year)
      @scope = School.none unless ContractPeriod.exists?(year: contract_period_year)
    end

    def or_where_school_partnership_exists(contract_period_year)
      return if ignore?(filter: contract_period_year)

      @scope = scope.or(
        School
          .where(id: School.select("schools.id")
          .joins(school_partnerships: { lead_provider_delivery_partnership: { active_lead_provider: :contract_period } })
          .where(contract_periods: { year: contract_period_year }))
      ).distinct
    end

    def where_urn_is(urn)
      return if ignore?(filter: urn)

      scope.merge!(School.where(urn:))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      scope.merge!(School.where(api_updated_at: updated_since..))
    end

    def set_sort_by(sort)
      @scope = scope.order(sort)
    end
  end
end
