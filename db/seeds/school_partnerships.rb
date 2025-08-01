def describe_school_partnership(sp)
  delivery_partner_name = sp.lead_provider_delivery_partnership.delivery_partner.name
  lead_provider_name = sp.lead_provider_delivery_partnership.active_lead_provider.lead_provider.name
  contract_period_year = sp.lead_provider_delivery_partnership.active_lead_provider.contract_period.year
  school_name = "Some School" # sp.school.gias_school.name

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
      active_lead_provider: { lead_provider:, contract_period: }
    )
end

abbey_grove_school = School.find_by!(urn: 1_759_427)
ackley_bridge = School.find_by!(urn: 3_375_958)
mallory_towers = School.find_by!(urn: 5_279_293)
brookfield_school = School.find_by!(urn: 2_976_163)

rp2022 = ContractPeriod.find_by(year: 2022)
rp2023 = ContractPeriod.find_by(year: 2023)
rp2025 = ContractPeriod.find_by(year: 2025)

ambitious_institute = LeadProvider.find_by!(name: 'Ambitious Institute')
teach_fast = LeadProvider.find_by!(name: 'Teach Fast')

artisan = DeliveryPartner.find_by!(name: "Artisan Education Group")
grain = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")

ambitious_institute__artisan__2022 = find_lead_provider_delivery_partnership(delivery_partner: artisan, lead_provider: ambitious_institute, contract_period: rp2022)
ambitious_institute__artisan__2023 = find_lead_provider_delivery_partnership(delivery_partner: artisan, lead_provider: ambitious_institute, contract_period: rp2023)
teach_fast__grain__2022 = find_lead_provider_delivery_partnership(delivery_partner: grain, lead_provider: teach_fast, contract_period: rp2022)
teach_fast__grain__2023 = find_lead_provider_delivery_partnership(delivery_partner: grain, lead_provider: teach_fast, contract_period: rp2023)
teach_fast__grain__2025 = find_lead_provider_delivery_partnership(delivery_partner: grain, lead_provider: teach_fast, contract_period: rp2025)
[
  { school: abbey_grove_school, lead_provider_delivery_partnership: ambitious_institute__artisan__2022 },
  { school: abbey_grove_school, lead_provider_delivery_partnership: ambitious_institute__artisan__2023 },
  { school: abbey_grove_school, lead_provider_delivery_partnership: teach_fast__grain__2023 },
  { school: abbey_grove_school, lead_provider_delivery_partnership: teach_fast__grain__2025 },
  { school: ackley_bridge, lead_provider_delivery_partnership: ambitious_institute__artisan__2023 },
  { school: mallory_towers, lead_provider_delivery_partnership: teach_fast__grain__2022 },
  { school: brookfield_school, lead_provider_delivery_partnership: teach_fast__grain__2022 },
].each { |kwargs| SchoolPartnership.create!(**kwargs).tap { |sp| describe_school_partnership(sp) } }
