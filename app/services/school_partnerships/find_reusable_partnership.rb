module SchoolPartnerships
  class FindReusablePartnership
    include ContractPeriodYearConcern

    # Returns a single SchoolPartnership (the best match) or nil
    def call(school:, lead_provider:, contract_period:)
      return nil unless school && lead_provider && contract_period

      contract_period_year = to_year(contract_period)

      active_lead_provider =
        find_active_lead_provider(
          lead_provider:,
          contract_period_year:
        )

      return nil unless active_lead_provider

      base_scope =
        base_school_partnership_scope(
          school:,
          lead_provider:,
          active_lead_provider:
        )

      current_year_partnership(base_scope, contract_period_year) ||
        most_recent_compatible_partnership(base_scope)
    end

  private

    def find_active_lead_provider(lead_provider:, contract_period_year:)
      ActiveLeadProvider
        .for_lead_provider(lead_provider.id)
        .for_contract_period_year(contract_period_year)
        .first
    end

    def base_school_partnership_scope(school:, lead_provider:, active_lead_provider:)
      SchoolPartnerships::Search
        .new(school:, lead_provider:)
        .school_partnerships
        .joins(lead_provider_delivery_partnership: :active_lead_provider)
        .where(
          lead_provider_delivery_partnership: {
            delivery_partner_id:
              delivery_partner_ids_for(active_lead_provider)
          }
        )
        .unscope(:order)
    end

    def delivery_partner_ids_for(active_lead_provider)
      active_lead_provider
        .lead_provider_delivery_partnerships
        .select(:delivery_partner_id)
    end

    def current_year_partnership(base_scope, contract_period_year)
      base_scope
        .where(active_lead_providers: { contract_period_year: })
        .order(created_at: :desc, id: :desc)
        .first
    end

    def most_recent_compatible_partnership(base_scope)
      base_scope
        .reorder(
          "active_lead_providers.contract_period_year DESC",
          created_at: :desc,
          id: :desc
        )
        .first
    end
  end
end
