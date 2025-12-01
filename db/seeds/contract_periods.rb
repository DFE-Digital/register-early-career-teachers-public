def describe_contract_period(cp)
  print_seed_info("#{cp.year} (running from #{cp.started_on} until #{cp.finished_on})", indent: 2)
end

# Seed contract periods and attributes same as in production
[
  { year: 2021, enabled: false, payments_frozen_at: Time.zone.local(2024, 6, 18) },
  { year: 2022, enabled: false, payments_frozen_at: Time.zone.local(2025, 6, 16) },
  { year: 2023, enabled: true },
  { year: 2024, enabled: true },
  { year: 2025, enabled: true },
  { year: 2026, enabled: false }
].each do |data|
  FactoryBot.create(:contract_period,
                    year: data[:year],
                    enabled: data[:enabled],
                    payments_frozen_at: data[:payments_frozen_at]).tap { |cp| describe_contract_period(cp) }
end
