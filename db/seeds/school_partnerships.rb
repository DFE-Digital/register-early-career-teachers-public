def describe_school_partnership(sp)
  delivery_partner_name = sp.lead_provider_delivery_partnership.delivery_partner.name
  lead_provider_name = sp.lead_provider_delivery_partnership.active_lead_provider.lead_provider.name
  contract_period_year = sp.lead_provider_delivery_partnership.active_lead_provider.contract_period.year
  school_name = sp.school.gias_school.name

  print_seed_info("#{school_name} has partnered with:")
  print_seed_info("🤝 lead provider: #{lead_provider_name}", indent: 4)
  print_seed_info("🤝 delivery partner: #{delivery_partner_name}", indent: 4)
  print_seed_info("🤝 contract period: #{contract_period_year}", indent: 4)
end

def find_lead_provider_delivery_partnership(lead_provider:, delivery_partner:, contract_period:)
  LeadProviderDeliveryPartnership
    .joins(active_lead_provider: %i[contract_period lead_provider])
    .find_by(
      delivery_partner:,
      active_lead_provider: {lead_provider:, contract_period:}
    )
end

abbey_grove_school = School.find_by!(urn: 1_759_427)
ackley_bridge = School.find_by!(urn: 3_375_958)
mallory_towers = School.find_by!(urn: 5_279_293)
brookfield_school = School.find_by!(urn: 2_976_163)

rp2021 = ContractPeriod.find_by(year: 2021)
rp2022 = ContractPeriod.find_by(year: 2022)
rp2023 = ContractPeriod.find_by(year: 2023)
rp2024 = ContractPeriod.find_by(year: 2024)
rp2025 = ContractPeriod.find_by(year: 2025)

ambition_institute = LeadProvider.find_by!(name: "Ambition Institute")
teach_first = LeadProvider.find_by!(name: "Teach First")
capita = LeadProvider.find_by!(name: "Capita")

artisan = DeliveryPartner.find_by!(name: "Artisan Education Group")
grain = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")
capita_delivery_partner = DeliveryPartner.find_by!(name: "Capita Delivery Partner")

ambition_institute__artisan__2021 = find_lead_provider_delivery_partnership(delivery_partner: artisan, lead_provider: ambition_institute, contract_period: rp2021)
ambition_institute__artisan__2022 = find_lead_provider_delivery_partnership(delivery_partner: artisan, lead_provider: ambition_institute, contract_period: rp2022)
ambition_institute__artisan__2023 = find_lead_provider_delivery_partnership(delivery_partner: artisan, lead_provider: ambition_institute, contract_period: rp2023)
teach_first__grain__2021 = find_lead_provider_delivery_partnership(delivery_partner: grain, lead_provider: teach_first, contract_period: rp2021)
teach_first__grain__2022 = find_lead_provider_delivery_partnership(delivery_partner: grain, lead_provider: teach_first, contract_period: rp2022)
teach_first__grain__2023 = find_lead_provider_delivery_partnership(delivery_partner: grain, lead_provider: teach_first, contract_period: rp2023)
teach_first__grain__2024 = find_lead_provider_delivery_partnership(delivery_partner: grain, lead_provider: teach_first, contract_period: rp2024)
teach_first__grain__2025 = find_lead_provider_delivery_partnership(delivery_partner: grain, lead_provider: teach_first, contract_period: rp2025)
capita__delivery_partner__2022 = find_lead_provider_delivery_partnership(delivery_partner: capita_delivery_partner, lead_provider: capita, contract_period: rp2022)

[
  {school: abbey_grove_school, lead_provider_delivery_partnership: ambition_institute__artisan__2022},
  {school: abbey_grove_school, lead_provider_delivery_partnership: ambition_institute__artisan__2023},
  {school: abbey_grove_school, lead_provider_delivery_partnership: teach_first__grain__2023},
  {school: abbey_grove_school, lead_provider_delivery_partnership: teach_first__grain__2024},
  {school: abbey_grove_school, lead_provider_delivery_partnership: teach_first__grain__2025},
  {school: ackley_bridge, lead_provider_delivery_partnership: ambition_institute__artisan__2021},
  {school: ackley_bridge, lead_provider_delivery_partnership: ambition_institute__artisan__2023},
  {school: mallory_towers, lead_provider_delivery_partnership: teach_first__grain__2021},
  {school: mallory_towers, lead_provider_delivery_partnership: teach_first__grain__2022},
  {school: brookfield_school, lead_provider_delivery_partnership: teach_first__grain__2022},
  {school: brookfield_school, lead_provider_delivery_partnership: capita__delivery_partner__2022}
].each { |kwargs| FactoryBot.create(:school_partnership, **kwargs).tap { |sp| describe_school_partnership(sp) } }
