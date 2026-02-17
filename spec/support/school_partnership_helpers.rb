module SchoolPartnershipHelpers
  def make_partnership_for(school, contract_period, lead_provider_name: "Xavier's School for Gifted Youngsters", delivery_partner_name: "Yvette's Institute for Gifted Teachers")
    lead_provider = FactoryBot.create(:lead_provider, name: lead_provider_name)
    active_lead_provider = FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:)
    delivery_partner = FactoryBot.create(:delivery_partner, name: delivery_partner_name)
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)

    FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:)
  end
end
