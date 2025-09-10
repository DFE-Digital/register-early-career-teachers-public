def describe_contract_period(cp)
  print_seed_info("#{cp.year} (running from #{cp.started_on} until #{cp.finished_on})", indent: 2)
end

{
  2021 => false,
  2022 => false,
  2023 => true,
  2024 => true,
  2025 => true,
  2026 => false
}.each do |year, enabled|
  FactoryBot.create(:contract_period,
                    year:,
                    enabled:).tap { |cp| describe_contract_period(cp) }
end
