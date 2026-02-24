def describe_lead_provider(lead_provider, years)
  years_description = if years.any?
                        Colourize.text(years.join(", "), :green)
                      else
                        Colourize.text("inactive", :red)
                      end

  print_seed_info("#{lead_provider.name} (#{years_description})", indent: 2)
end

lead_providers_data = [
  { name: "Grove Institute", years: [2021, 2022, 2023, 2024, 2025, 2026], vat_registered: true },
  { name: "Evergreen Network", years: [2022, 2023, 2024, 2025], vat_registered: true },
  { name: "National Meadows Institute", years: [2021, 2022, 2023], vat_registered: true },
  { name: "Woodland Education Trust", years: [2021, 2022, 2023, 2024, 2025], vat_registered: true },
  { name: "Highland College University", years: [2021], vat_registered: false },
  { name: "Wildflower Trust", years: [2021, 2022, 2023, 2024, 2025], vat_registered: false },
  { name: "Pine Institute", years: [2021, 2022, 2023, 2024, 2025], vat_registered: true },
]

lead_providers_data.each do |data|
  lead_provider = LeadProvider.find_or_create_by!(data.slice(:name, :vat_registered))

  data[:years].each do |year|
    contract_period = ContractPeriod.find_by!(year:)
    ActiveLeadProvider.find_or_create_by!(lead_provider:, contract_period:)
  end

  describe_lead_provider(lead_provider, data[:years])
end
