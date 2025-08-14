def describe_lead_provider_delivery_partnership(lpdp)
  alp = lpdp.active_lead_provider
  print_seed_info("#{lpdp.delivery_partner.name} are working with #{alp.lead_provider.name} in #{alp.contract_period.year}")
end

ambition_institute = LeadProvider.find_by!(name: 'Ambition Institute')
teach_first = LeadProvider.find_by!(name: 'Teach First')
best_practice_network = LeadProvider.find_by!(name: 'Best Practice Network')

active_lead_providers = ActiveLeadProvider
  .eager_load(:contract_period, :lead_provider)
  .index_by { |alp| [alp.lead_provider, alp.contract_period.year] }

ambition_institute_2022 = active_lead_providers.fetch([ambition_institute, 2022])
ambition_institute_2023 = active_lead_providers.fetch([ambition_institute, 2023])
ambition_institute_2024 = active_lead_providers.fetch([ambition_institute, 2024])
ambition_institute_2026 = active_lead_providers.fetch([ambition_institute, 2026])
teach_first_2022 = active_lead_providers.fetch([teach_first, 2022])
teach_first_2023 = active_lead_providers.fetch([teach_first, 2023])
teach_first_2024 = active_lead_providers.fetch([teach_first, 2024])
teach_first_2025 = active_lead_providers.fetch([teach_first, 2025])
best_practice_network_2023 = active_lead_providers.fetch([best_practice_network, 2023])
best_practice_network_2024 = active_lead_providers.fetch([best_practice_network, 2024])

artisan = DeliveryPartner.find_by!(name: "Artisan Education Group")
grain = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")
rising_minds = DeliveryPartner.find_by!(name: "Rising Minds Network")

[
  { active_lead_provider: ambition_institute_2022, delivery_partner: artisan },
  { active_lead_provider: ambition_institute_2023, delivery_partner: artisan },
  { active_lead_provider: ambition_institute_2024, delivery_partner: artisan },
  { active_lead_provider: ambition_institute_2026, delivery_partner: artisan },
  { active_lead_provider: teach_first_2022, delivery_partner: grain },
  { active_lead_provider: teach_first_2023, delivery_partner: grain },
  { active_lead_provider: teach_first_2024, delivery_partner: grain },
  { active_lead_provider: teach_first_2025, delivery_partner: grain },
  { active_lead_provider: best_practice_network_2023, delivery_partner: rising_minds },
  { active_lead_provider: best_practice_network_2024, delivery_partner: rising_minds }
].each do |data|
  LeadProviderDeliveryPartnership.find_or_create_by!(
    active_lead_provider: data[:active_lead_provider],
    delivery_partner: data[:delivery_partner]
  ).tap { |lpdp| describe_lead_provider_delivery_partnership(lpdp) }
end
