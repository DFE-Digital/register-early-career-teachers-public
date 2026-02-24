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

grove_institute = LeadProvider.find_by!(name: "Grove Institute")
wildflower_trust = LeadProvider.find_by!(name: "Wildflower Trust")
evergreen_network = LeadProvider.find_by!(name: "Evergreen Network")
national_meadows_institute = LeadProvider.find_by!(name: "National Meadows Institute")

active_lead_providers = ActiveLeadProvider
  .eager_load(:contract_period, :lead_provider)
  .index_by { |alp| [alp.lead_provider, alp.contract_period.year] }

grove_institute_2021 = active_lead_providers.fetch([grove_institute, 2021])
grove_institute_2022 = active_lead_providers.fetch([grove_institute, 2022])
grove_institute_2023 = active_lead_providers.fetch([grove_institute, 2023])
grove_institute_2024 = active_lead_providers.fetch([grove_institute, 2024])
grove_institute_2025 = active_lead_providers.fetch([grove_institute, 2025])
grove_institute_2026 = active_lead_providers.fetch([grove_institute, 2026])
wildflower_trust_2021 = active_lead_providers.fetch([wildflower_trust, 2021])
wildflower_trust_2022 = active_lead_providers.fetch([wildflower_trust, 2022])
wildflower_trust_2023 = active_lead_providers.fetch([wildflower_trust, 2023])
wildflower_trust_2024 = active_lead_providers.fetch([wildflower_trust, 2024])
wildflower_trust_2025 = active_lead_providers.fetch([wildflower_trust, 2025])
evergreen_network_2023 = active_lead_providers.fetch([evergreen_network, 2023])
evergreen_network_2024 = active_lead_providers.fetch([evergreen_network, 2024])
national_meadows_institute_2022 = active_lead_providers.fetch([national_meadows_institute, 2022])

artisan = DeliveryPartner.find_by!(name: "Artisan Education Group")
grain = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")
rising_minds = DeliveryPartner.find_by!(name: "Rising Minds Network")
harvest = DeliveryPartner.find_by!(name: "Harvest Academy")

lead_provider_delivery_partnerships = []

[
  { active_lead_provider: grove_institute_2021, delivery_partner: artisan },
  { active_lead_provider: grove_institute_2022, delivery_partner: artisan },
  { active_lead_provider: grove_institute_2023, delivery_partner: artisan },
  { active_lead_provider: grove_institute_2024, delivery_partner: artisan },
  { active_lead_provider: grove_institute_2025, delivery_partner: artisan },
  { active_lead_provider: grove_institute_2026, delivery_partner: artisan },
  { active_lead_provider: wildflower_trust_2021, delivery_partner: grain },
  { active_lead_provider: wildflower_trust_2022, delivery_partner: grain },
  { active_lead_provider: wildflower_trust_2023, delivery_partner: grain },
  { active_lead_provider: wildflower_trust_2024, delivery_partner: grain },
  { active_lead_provider: wildflower_trust_2025, delivery_partner: grain },
  { active_lead_provider: evergreen_network_2023, delivery_partner: rising_minds },
  { active_lead_provider: evergreen_network_2024, delivery_partner: rising_minds },
  { active_lead_provider: national_meadows_institute_2022, delivery_partner: harvest }
].each do |data|
  LeadProviderDeliveryPartnership
    .find_or_create_by!(
      active_lead_provider: data[:active_lead_provider],
      delivery_partner: data[:delivery_partner]
    )
    .tap { lead_provider_delivery_partnerships << it }
end

# These are additional delivery partnerships useful for testing.

all_delivery_partners = DeliveryPartner.all

ActiveLeadProvider.find_each do |active_lead_provider|
  all_delivery_partners.sample(rand(1..3)).each do |delivery_partner|
    next if LeadProviderDeliveryPartnership.exists?(active_lead_provider:, delivery_partner:)

    LeadProviderDeliveryPartnership
      .create!(
        active_lead_provider:,
        delivery_partner:
      )
      .tap { lead_provider_delivery_partnerships << it }
  end
end

describe_lead_provider_delivery_partnerships(lead_provider_delivery_partnerships)
