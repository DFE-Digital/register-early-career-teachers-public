def describe_lead_provider(lead_provider, years)
  years_description = if years.any?
                        Colourize.text(years.join(', '), :green)
                      else
                        Colourize.text('inactive', :red)
                      end

  print_seed_info("#{lead_provider.name} (#{years_description})", indent: 2)
end

lead_providers_data = [
  { name: 'Ambition Institute', years: [2021, 2022, 2023, 2024, 2025, 2026] },
  { name: 'Best Practice Network', years: [2022, 2023, 2024, 2025] },
  { name: 'Capita', years: [2021, 2022, 2023] },
  { name: 'Education Development Trust', years: [2021, 2022, 2023, 2024, 2025] },
  { name: 'National Institute of Teaching', years: [2021] },
  { name: 'Teach First', years: [2021, 2022, 2023, 2024, 2025] },
  { name: 'UCL Institute of Education', years: [2021, 2022, 2023, 2024, 2025] },
]

lead_providers_data.each do |data|
  lead_provider = FactoryBot.create(:lead_provider, name: data[:name])
  data[:years].each do |year|
    contract_period = ContractPeriod.find_by!(year:)
    FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:)
  end

  describe_lead_provider(lead_provider, data[:years])
end
