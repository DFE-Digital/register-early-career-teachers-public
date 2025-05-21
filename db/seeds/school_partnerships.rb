def describe_school_partnership(pp)
  print_seed_info("#{pp.lead_provider.name} (LP) 🤝 #{pp.delivery_partner.name} (DP) in #{pp.registration_period.year}", indent: 2)
end

ambitious_institute = LeadProvider.find_by!(name: 'Ambitious Institute')
teach_fast = LeadProvider.find_by!(name: 'Teach Fast')
better_practice_network = LeadProvider.find_by!(name: 'Better Practice Network')

rp_2021 = RegistrationPeriod.find_by!(year: 2021)
rp_2022 = RegistrationPeriod.find_by!(year: 2022)
rp_2023 = RegistrationPeriod.find_by!(year: 2023)
rp_2024 = RegistrationPeriod.find_by!(year: 2024)

artisan_education_group = DeliveryPartner.find_by!(name: 'Artisan Education Group')
grain_teaching_school_hub = DeliveryPartner.find_by!(name: 'Grain Teaching School Hub')
rising_minds = DeliveryPartner.find_by!(name: 'Rising Minds Network')

SchoolPartnership.create!(
  registration_period: rp_2021,
  lead_provider: ambitious_institute,
  delivery_partner: artisan_education_group
).tap { |pp| describe_school_partnership(pp) }

SchoolPartnership.create!(
  registration_period: rp_2022,
  lead_provider: ambitious_institute,
  delivery_partner: artisan_education_group
).tap { |pp| describe_school_partnership(pp) }

SchoolPartnership.create!(
  registration_period: rp_2023,
  lead_provider: ambitious_institute,
  delivery_partner: artisan_education_group
).tap { |pp| describe_school_partnership(pp) }

SchoolPartnership.create!(
  registration_period: rp_2022,
  lead_provider: teach_fast,
  delivery_partner: grain_teaching_school_hub
).tap { |pp| describe_school_partnership(pp) }

SchoolPartnership.create!(
  registration_period: rp_2023,
  lead_provider: teach_fast,
  delivery_partner: grain_teaching_school_hub
).tap { |pp| describe_school_partnership(pp) }

SchoolPartnership.create!(
  registration_period: rp_2023,
  lead_provider: better_practice_network,
  delivery_partner: rising_minds
).tap { |pp| describe_school_partnership(pp) }

SchoolPartnership.create!(
  registration_period: rp_2024,
  lead_provider: better_practice_network,
  delivery_partner: rising_minds
).tap { |pp| describe_school_partnership(pp) }
