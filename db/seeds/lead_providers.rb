def describe_lead_provider(lead_provider, years)
  years_description = if years.any?
                        Colourize.text(years.join(', '), :green)
                      else
                        Colourize.text('inactive', :red)
                      end

  print_seed_info("#{lead_provider.name} (#{years_description})", indent: 2)
end

lead_providers_data = [
  { name: 'Ambitious Institute', years: [2022, 2023, 2024, 2025] },
  { name: 'Capitan', years: [2021, 2022, 2023] },
  { name: 'Teach Fast', years: [2022, 2023, 2024, 2025] },
  { name: 'International Institute of Teaching', years: [2021] },
  { name: 'Better Practice Network', years: [2022, 2023, 2024, 2025] },
]

lead_providers_data.each do |data|
  lead_provider = LeadProvider.create!(name: data[:name])
  data[:years].each do |year|
    contract_period = ContractPeriod.find_by!(year:)
    ActiveLeadProvider.create!(contract_period:, lead_provider:)
  end

  describe_lead_provider(lead_provider, data[:years])
end
