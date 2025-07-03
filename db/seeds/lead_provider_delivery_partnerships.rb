def describe_lead_provider_delivery_partnership(lpdp)
  alp = lpdp.active_lead_provider
  print_seed_info("#{lpdp.delivery_partner.name} are working with #{alp.lead_provider.name} in #{alp.contract_period.year}")
end

ambitious_institute = LeadProvider.find_by!(name: 'Ambitious Institute')
teach_fast = LeadProvider.find_by!(name: 'Teach Fast')
better_practice_network = LeadProvider.find_by!(name: 'Better Practice Network')

active_lead_providers = ActiveLeadProvider
  .eager_load(:contract_period, :lead_provider)
  .index_by { |alp| [alp.lead_provider, alp.contract_period.year] }

ambitious_institute_2022 = active_lead_providers.fetch([ambitious_institute, 2022])
ambitious_institute_2023 = active_lead_providers.fetch([ambitious_institute, 2023])
ambitious_institute_2024 = active_lead_providers.fetch([ambitious_institute, 2024])
teach_fast_2022 = active_lead_providers.fetch([teach_fast, 2022])
teach_fast_2023 = active_lead_providers.fetch([teach_fast, 2023])
better_practice_network_2023 = active_lead_providers.fetch([better_practice_network, 2023])
better_practice_network_2024 = active_lead_providers.fetch([better_practice_network, 2024])

artisan = DeliveryPartner.find_by!(name: "Artisan Education Group")
grain = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")
rising_minds = DeliveryPartner.find_by!(name: "Rising Minds Network")

[
  { active_lead_provider: ambitious_institute_2022, delivery_partner: artisan },
  { active_lead_provider: ambitious_institute_2023, delivery_partner: artisan },
  { active_lead_provider: ambitious_institute_2024, delivery_partner: artisan },
  { active_lead_provider: teach_fast_2022, delivery_partner: grain },
  { active_lead_provider: teach_fast_2023, delivery_partner: grain },
  { active_lead_provider: better_practice_network_2023, delivery_partner: rising_minds },
  { active_lead_provider: better_practice_network_2024, delivery_partner: rising_minds }
].each do |data|
  LeadProviderDeliveryPartnership.create!(
    active_lead_provider: data[:active_lead_provider],
    delivery_partner: data[:delivery_partner]
  ).tap { |lpdp| describe_lead_provider_delivery_partnership(lpdp) }
end
