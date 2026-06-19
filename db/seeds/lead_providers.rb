def describe_lead_provider(lead_provider, years, token)
  years_description = if years.any?
                        Colourize.text(years.join(", "), :green)
                      else
                        Colourize.text("inactive", :red)
                      end

  print_seed_info("#{lead_provider.name} (#{years_description})", indent: 2)
  print_seed_info("🔑 Token: #{token}", indent: 4)
end

lead_providers_data = [
  { name: "Ambition Institute", years: [2021, 2022, 2023, 2024, 2025, 2026], vat_registered: true },
  { name: "Best Practice Network", years: [2022, 2023, 2024, 2025, 2026], vat_registered: true },
  { name: "Capita", years: [2021, 2022, 2023], vat_registered: true },
  { name: "Education Development Trust", years: [2021, 2022, 2023, 2024, 2025, 2026], vat_registered: true },
  { name: "National Institute of Teaching", years: [2021], vat_registered: false },
  { name: "Teach First", years: [2021, 2022, 2023, 2024, 2025, 2026], vat_registered: false },
  { name: "UCL Institute of Education", years: [2021, 2022, 2023, 2024, 2025, 2026], vat_registered: true },
]

lead_providers_data.each do |data|
  lead_provider = FactoryBot.create(:lead_provider, data.slice(:name, :vat_registered))

  data[:years].each do |year|
    contract_period = ContractPeriod.find_by!(year:)
    ActiveLeadProvider.find_or_create_by!(lead_provider:, contract_period:)
  end

  token = lead_provider.name.parameterize

  FactoryBot.create(:api_token,
                    lead_provider:,
                    token:,
                    description: "A lead provider token for #{lead_provider.name}",
                    last_used_at: nil)

  describe_lead_provider(lead_provider, data[:years], token)
end
