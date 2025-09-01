module API::DeliveryPartners
  class Query
    include Queries::ConditionFormats
    include Queries::Orderable
    include Queries::FilterIgnorable

    attr_reader :scope, :lead_provider_id

    def initialize(lead_provider_id: :ignore, contract_period_years: :ignore, sort: nil)
      @lead_provider_id = lead_provider_id
      @scope = DeliveryPartner.distinct

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

    def preload_associations(results)
      preloaded_results = results
        .strict_loading
        .includes(:lead_provider_metadata)

      unless ignore?(filter: lead_provider_id)
        preloaded_results = preloaded_results
          .references(:metadata_delivery_partners_lead_providers)
          .where(metadata_delivery_partners_lead_providers: { lead_provider_id: })
      end

      preloaded_results
    end

    def where_lead_provider_is(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      delivery_partners_with_lead_provider = DeliveryPartner
        .joins(lead_provider_delivery_partnerships: :active_lead_provider)
        .where(active_lead_provider: { lead_provider_id: })

      scope.merge!(delivery_partners_with_lead_provider)
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years)

      delivery_partners_with_contract_periods = DeliveryPartner
        .joins(lead_provider_delivery_partnerships: { active_lead_provider: :contract_period })
        .where(active_lead_provider: { contract_period_year: extract_conditions(contract_period_years, integers: true) })

      scope.merge!(delivery_partners_with_contract_periods)
    end

    def set_sort_by(sort)
      @scope = scope.order(sort_order(sort:, model: DeliveryPartner, default: { created_at: :asc }))
    end
  end
end
