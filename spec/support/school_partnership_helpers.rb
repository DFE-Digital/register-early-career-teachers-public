module SchoolPartnershipHelpers
  def make_partnership_for(school, contract_period)
    active_lead_provider = FactoryBot.create(:active_lead_provider, contract_period:)
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)

    FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:)
  end
end
