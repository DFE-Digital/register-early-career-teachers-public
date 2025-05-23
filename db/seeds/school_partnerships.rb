def describe_school_partnership(pp)
  print_seed_info("#{pp.lead_provider.name} (lead_provider) 🤝 #{pp.delivery_partner.name} (delivery_partner) in #{pp.registration_period.year}", indent: 2)
end

lead_providers = {
  ambitious_institute: LeadProvider.find_by!(name: 'Ambitious Institute'),
  teach_fast: LeadProvider.find_by!(name: 'Teach Fast'),
  better_practice_network: LeadProvider.find_by!(name: 'Better Practice Network'),
}

delivery_partners = {
  artisan: DeliveryPartner.find_by(name: "Artisan Education Group"),
  grain: DeliveryPartner.find_by(name: "Grain Teaching School Hub"),
  rising_minds: DeliveryPartner.find_by(name: "Rising Minds Network")
}

registration_periods = {
  2021 => RegistrationPeriod.find_by(year: 2021),
  2022 => RegistrationPeriod.find_by(year: 2022),
  2023 => RegistrationPeriod.find_by(year: 2023),
  2024 => RegistrationPeriod.find_by(year: 2024)
}

[
  { year: 2021, lead_provider: :ambitious_institute, delivery_partner: :artisan },
  { year: 2022, lead_provider: :ambitious_institute, delivery_partner: :artisan },
  { year: 2023, lead_provider: :ambitious_institute, delivery_partner: :artisan },
  { year: 2022, lead_provider: :teach_fast, delivery_partner: :grain },
  { year: 2023, lead_provider: :teach_fast, delivery_partner: :grain },
  { year: 2023, lead_provider: :better_practice_network, delivery_partner: :rising_minds },
  { year: 2024, lead_provider: :better_practice_network, delivery_partner: :rising_minds }
].each do |data|
  SchoolPartnership.create!(
    registration_period: registration_periods[data[:year]],
    lead_provider: lead_providers[data[:lead_provider]],
    delivery_partner: delivery_partners[data[:delivery_partner]]
  ).tap { |pp| describe_school_partnership(pp) }
end
