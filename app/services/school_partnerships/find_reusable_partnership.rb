module SchoolPartnerships
  class FindReusablePartnership
    include ContractPeriodYearConcern

    # Returns a single SchoolPartnership (the best match) or nil
    def call(school:, lead_provider:, contract_period:)
      return nil unless school && lead_provider && contract_period

      year = to_year(contract_period)

      active_lead_provider =
        ActiveLeadProvider
          .for_lead_provider(lead_provider.id)
          .for_contract_period_year(year)
          .first
      return nil unless active_lead_provider

      base = SchoolPartnerships::Search
               .new(school:, lead_provider:)
               .school_partnerships
               .joins(lead_provider_delivery_partnership: :active_lead_provider)
               .where(
                 lead_provider_delivery_partnership: {
                   delivery_partner_id: current_year_delivery_partner_ids(active_lead_provider)
                 }
               )
               .unscope(:order)

      current_year_partnership(base, year) || most_recent_compatible_partnership(base)
    end

  private

    def current_year_delivery_partner_ids(active_lead_provider)
      active_lead_provider
        .lead_provider_delivery_partnerships
        .select(:delivery_partner_id)
    end

    def current_year_partnership(base, year)
      base
        .where(active_lead_providers: { contract_period_year: year })
        .order(created_at: :desc, id: :desc)
        .first
    end

    def most_recent_compatible_partnership(base)
      base
        .reorder("active_lead_providers.contract_period_year DESC", created_at: :desc, id: :desc)
        .first
    end
  end
end
