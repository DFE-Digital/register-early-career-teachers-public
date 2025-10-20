def describe_lead_provider_delivery_partnerships(lead_provider_delivery_partnerships)
  lead_provider_delivery_partnerships
    .group_by { it.active_lead_provider.contract_period_year }
    .sort
    .to_h
    .each do |year, lpdps|
      print_seed_info(Colourize.text(year, :yellow), indent: 2)

      lpdps.group_by(&:lead_provider).each do |lead_provider, lpdp|
        print_seed_info(Colourize.text(lead_provider.name + " is working with:", :cyan), indent: 4)

        lpdp.each { print_seed_info(it.delivery_partner.name, indent: 6) }
      end
    end
end

# These delivery partnerships are used by other seeds, so are created explicitly.

ambition_institute = LeadProvider.find_by!(name: "Ambition Institute")
teach_first = LeadProvider.find_by!(name: "Teach First")
best_practice_network = LeadProvider.find_by!(name: "Best Practice Network")
capita = LeadProvider.find_by!(name: "Capita")

active_lead_providers = ActiveLeadProvider
  .eager_load(:contract_period, :lead_provider)
  .index_by { |alp| [alp.lead_provider, alp.contract_period.year] }

ambition_institute_2021 = active_lead_providers.fetch([ambition_institute, 2021])
ambition_institute_2022 = active_lead_providers.fetch([ambition_institute, 2022])
ambition_institute_2023 = active_lead_providers.fetch([ambition_institute, 2023])
ambition_institute_2024 = active_lead_providers.fetch([ambition_institute, 2024])
ambition_institute_2026 = active_lead_providers.fetch([ambition_institute, 2026])
teach_first_2021 = active_lead_providers.fetch([teach_first, 2021])
teach_first_2022 = active_lead_providers.fetch([teach_first, 2022])
teach_first_2023 = active_lead_providers.fetch([teach_first, 2023])
teach_first_2024 = active_lead_providers.fetch([teach_first, 2024])
teach_first_2025 = active_lead_providers.fetch([teach_first, 2025])
best_practice_network_2023 = active_lead_providers.fetch([best_practice_network, 2023])
best_practice_network_2024 = active_lead_providers.fetch([best_practice_network, 2024])
capita_2022 = active_lead_providers.fetch([capita, 2022])

artisan = DeliveryPartner.find_by!(name: "Artisan Education Group")
grain = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")
rising_minds = DeliveryPartner.find_by!(name: "Rising Minds Network")
capita_delivery_partner = DeliveryPartner.find_by!(name: "Capita Delivery Partner")

lead_provider_delivery_partnerships = []

[
  {active_lead_provider: ambition_institute_2021, delivery_partner: artisan},
  {active_lead_provider: ambition_institute_2022, delivery_partner: artisan},
  {active_lead_provider: ambition_institute_2023, delivery_partner: artisan},
  {active_lead_provider: ambition_institute_2024, delivery_partner: artisan},
  {active_lead_provider: ambition_institute_2026, delivery_partner: artisan},
  {active_lead_provider: teach_first_2021, delivery_partner: grain},
  {active_lead_provider: teach_first_2022, delivery_partner: grain},
  {active_lead_provider: teach_first_2023, delivery_partner: grain},
  {active_lead_provider: teach_first_2024, delivery_partner: grain},
  {active_lead_provider: teach_first_2025, delivery_partner: grain},
  {active_lead_provider: best_practice_network_2023, delivery_partner: rising_minds},
  {active_lead_provider: best_practice_network_2024, delivery_partner: rising_minds},
  {active_lead_provider: capita_2022, delivery_partner: capita_delivery_partner}
].each do |data|
  FactoryBot.create(:lead_provider_delivery_partnership,
    active_lead_provider: data[:active_lead_provider],
    delivery_partner: data[:delivery_partner]).tap { lead_provider_delivery_partnerships << it }
end

# These are additional delivery partnerships useful for testing.

all_delivery_partners = DeliveryPartner.all

ActiveLeadProvider.find_each do |active_lead_provider|
  all_delivery_partners.sample(rand(1..3)).each do |delivery_partner|
    next if LeadProviderDeliveryPartnership.exists?(active_lead_provider:, delivery_partner:)

    FactoryBot
      .create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
      .tap { lead_provider_delivery_partnerships << it }
  end
end

describe_lead_provider_delivery_partnerships(lead_provider_delivery_partnerships)
