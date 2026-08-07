module API::Schools
  class Query
    include Queries::FilterIgnorable

    def initialize(
      contract_period_year:,
      lead_provider_id: :ignore,
      urn: :ignore,
      updated_since: :ignore,
      sort: { created_at: :asc },
      included_associations: []
    )
      @lead_provider_id = lead_provider_id
      @contract_period_year = contract_period_year
      @scope = School.eligible
      @included_associations = included_associations

      or_where_school_partnership_exists(contract_period_year)
      where_contract_period_exists(contract_period_year)
      where_lead_provider_is(lead_provider_id)
      where_contract_period_metadata_exists(contract_period_year)
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

    attr_reader :scope, :sort, :lead_provider_id, :contract_period_year, :included_associations

    def preload_associations(results)
      results
        .strict_loading
        .tap { it.includes!(*included_associations) if included_associations.present? }
    end

    def where_contract_period_exists(contract_period_year)
      @scope = School.none unless ContractPeriod.exists?(year: contract_period_year)
    end

    def or_where_school_partnership_exists(contract_period_year)
      return if ignore?(filter: contract_period_year)

      @scope = scope.or(School.where(id: school_ids_with_partnership(contract_period_year))).distinct
    end

    def school_ids_with_partnership(contract_period_year)
      SchoolPartnership
        .joins(lead_provider_delivery_partnership: :active_lead_provider)
        .where(active_lead_provider: { contract_period_year: })
        .select(:school_id)
    end

    def where_lead_provider_is(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      conditions = { lead_provider_id: }
      conditions[:contract_period_year] = contract_period_year unless ignore?(filter: contract_period_year)

      @scope = scope
        .joins(:lead_provider_contract_period_metadata)
        .where(metadata_schools_lead_providers_contract_periods: conditions)
    end

    def where_contract_period_metadata_exists(contract_period_year)
      return if ignore?(filter: contract_period_year)

      @scope = scope
        .joins(:contract_period_metadata)
        .where(metadata_schools_contract_periods: { contract_period_year: })
    end

    def where_urn_is(urn)
      return if ignore?(filter: urn)

      scope.merge!(School.where(urn:))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      scope.merge!(Metadata::SchoolContractPeriod.where(api_updated_at: updated_since..))
    end

    def set_sort_by(sort)
      @scope = scope.order(sort)
    end
  end
end
