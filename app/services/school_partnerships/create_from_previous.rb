module SchoolPartnerships
  class CreateFromPrevious
    def call(previous_school_partnership_id:, school:, author:, current_contract_period_year:)
      previous_school_partnership = SchoolPartnership
                                      .includes(lead_provider_delivery_partnership: :active_lead_provider)
                                      .find_by(id: previous_school_partnership_id)
      return nil unless previous_school_partnership

      lpdp_previous = previous_school_partnership.lead_provider_delivery_partnership
      active_lead_provider_previous = lpdp_previous&.active_lead_provider
      return nil unless lpdp_previous && active_lead_provider_previous

      previous_lead_provider_id = active_lead_provider_previous.lead_provider_id
      previous_delivery_partner_id = lpdp_previous.delivery_partner_id

      active_lead_provider_id_current_year = ActiveLeadProvider
                                               .for_lead_provider(previous_lead_provider_id)
                                               .for_contract_period_year(current_contract_period_year)
                                               .pick(:id)
      return nil unless active_lead_provider_id_current_year

      lead_provider_delivery_partnership_current_year = LeadProviderDeliveryPartnership.find_by(
        active_lead_provider_id: active_lead_provider_id_current_year,
        delivery_partner_id: previous_delivery_partner_id
      )
      return nil unless lead_provider_delivery_partnership_current_year

      SchoolPartnerships::Create
        .new(
          author:,
          school:,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership_current_year
        )
        .create
    end
  end
end
