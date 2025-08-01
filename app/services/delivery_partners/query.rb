module DeliveryPartners
  class Query
    include Queries::ConditionFormats
    include QueryOrderable
    include FilterIgnorable

    attr_reader :scope

    def initialize(lead_provider: :ignore, contract_period_years: :ignore, sort: nil)
      @scope = DeliveryPartner
        .select("delivery_partners.*", transient_cohorts_subquery(lead_provider:))
        .distinct

      where_lead_provider_is(lead_provider)
      where_contract_period_year_in(contract_period_years)
      set_sort_by(sort)
    end

    def delivery_partners
      scope
    end

    def delivery_partner_by_api_id(api_id)
      return scope.find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "You must specify an api_id")
    end

    def delivery_partner_by_id(id)
      return scope.find(id) if id.present?

      fail(ArgumentError, "You must specify an id")
    end

  private

    def transient_cohorts_subquery(lead_provider:)
      lead_provider_where_clause = %(AND active_lead_providers.lead_provider_id = #{ActiveRecord::Base.connection.quote(lead_provider.id)}) unless ignore?(filter: lead_provider)

      <<~SQL.squish
        (
          SELECT ARRAY(
            SELECT DISTINCT active_lead_providers.contract_period_id::text
            FROM lead_provider_delivery_partnerships
            INNER JOIN active_lead_providers ON active_lead_providers.id = lead_provider_delivery_partnerships.active_lead_provider_id
            WHERE lead_provider_delivery_partnerships.delivery_partner_id = delivery_partners.id #{lead_provider_where_clause}
            ORDER BY active_lead_providers.contract_period_id::text
          )
        ) AS transient_cohorts
      SQL
    end

    def where_lead_provider_is(lead_provider)
      return if ignore?(filter: lead_provider)

      delivery_partners_with_lead_provider = DeliveryPartner
        .joins(lead_provider_delivery_partnerships: :active_lead_provider)
        .where(active_lead_provider: { lead_provider_id: lead_provider.id })

      scope.merge!(delivery_partners_with_lead_provider)
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years)

      delivery_partners_with_contract_periods = DeliveryPartner
        .joins(lead_provider_delivery_partnerships: { active_lead_provider: :contract_period })
        .where(contract_period: { year: extract_conditions(contract_period_years, integers: true) })

      scope.merge!(delivery_partners_with_contract_periods)
    end

    def set_sort_by(sort)
      @scope = scope.order(sort_order(sort:, model: DeliveryPartner, default: { created_at: :asc }))
    end
  end
end
