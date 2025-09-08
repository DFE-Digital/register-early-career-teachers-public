module API::DeliveryPartners
  class Query
    include Queries::FilterIgnorable

    attr_reader :scope

    def initialize(lead_provider_id: :ignore, contract_period_years: :ignore, sort: { created_at: :asc })
      @scope = DeliveryPartner
        .includes(:lead_provider_metadata)
        .distinct

      where_lead_provider_is(lead_provider_id)
      where_contract_period_year_in(contract_period_years)
      set_sort_by(sort)
    end

    def delivery_partners
      scope
    end

    def delivery_partner_by_api_id(api_id)
      return scope.find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def delivery_partner_by_id(id)
      return scope.find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

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
        .where(contract_period: { year: contract_period_years })

      scope.merge!(delivery_partners_with_contract_periods)
    end

    def set_sort_by(sort)
      @scope = scope.order(sort)
    end
  end
end
