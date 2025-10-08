module SchoolPartnerships
  class FindPreviousReusable
    def call(school:, last_lead_provider:, current_contract_period:)
      return nil if school.blank? || last_lead_provider.blank? || current_contract_period.blank?

      current_year = current_contract_period.year

      active_lead_provider =
        ActiveLeadProvider
          .for_lead_provider(last_lead_provider.id)
          .for_contract_period_year(current_year)
          .take
      return nil unless active_lead_provider

      previous_partnerships =
        SchoolPartnerships::Search
          .new(school:, lead_provider: last_lead_provider)
          .school_partnerships
          .excluding_contract_period_year(current_year)
          .latest_by_contract_year
          .includes(:lead_provider_delivery_partnership)

      current_year_delivery_partner_ids =
        LeadProviderDeliveryPartnership
          .for_contract_period(current_contract_period)
          .with_active_lead_provider(active_lead_provider.id)
          .select(:delivery_partner_id)

      previous_partnerships
        .joins(:lead_provider_delivery_partnership)
        .where(lead_provider_delivery_partnership: { delivery_partner_id: current_year_delivery_partner_ids })
        .first
    end
  end
end
