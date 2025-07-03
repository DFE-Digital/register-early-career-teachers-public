def describe_contract_period(cp)
  print_seed_info("#{cp.year} (running from #{cp.started_on} until #{cp.finished_on})", indent: 2)
end

{
  2021 => false,
  2022 => false,
  2023 => true,
  2024 => true,
  2025 => true
}.each do |year, enabled|
  ContractPeriod.create!(
    year:,
    started_on: Date.new(year, 6, 1),
    finished_on: Date.new(year + 1, 5, 31),
    enabled:
  ).tap { |rp| describe_contract_period(rp) }
end
