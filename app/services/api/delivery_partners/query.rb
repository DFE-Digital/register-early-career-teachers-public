module API::DeliveryPartners
  class Query
    include Queries::FilterIgnorable

    def initialize(lead_provider_id: :ignore, contract_period_years: :ignore, sort: { created_at: :asc }, included_associations: [])
      @lead_provider_id = lead_provider_id
      @scope = DeliveryPartner.distinct
      @included_associations = included_associations

      where_lead_provider_is(lead_provider_id)
      where_contract_period_year_in(contract_period_years)
      set_sort_by(sort)
    end

    def delivery_partners
      preload_associations(block_given? ? yield(scope) : scope)
    end

    def delivery_partner_by_api_id(api_id)
      return preload_associations(scope).find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def delivery_partner_by_id(id)
      return preload_associations(scope).find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    attr_reader :scope, :lead_provider_id, :included_associations

    def preload_associations(results)
      results
        .strict_loading
        .tap { it.includes!(included_associations) if included_associations.present? }
    end

    def where_lead_provider_is(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      delivery_partners_with_lead_provider = DeliveryPartner
        .joins(:framework_agreements)
        .where(framework_agreements: { lead_provider_id: })

      scope.merge!(delivery_partners_with_lead_provider)
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years, ignore_empty_array: false)

      delivery_partners_with_contract_periods = DeliveryPartner
        .joins(lead_provider_delivery_partnerships: { framework_agreement: :contract_period })
        .where(framework_agreement: { contract_period_year: contract_period_years })

      scope.merge!(delivery_partners_with_contract_periods)
    end

    def set_sort_by(sort)
      @scope = scope.order(sort)
    end
  end
end
