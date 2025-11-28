def describe_contract_period(cp)
  print_seed_info("#{cp.year} (running from #{cp.started_on} until #{cp.finished_on})", indent: 2)
end

# Seed contract periods and attributes same as in production
[
  { year: 2021, enabled: false, payments_frozen_at: Time.zone.local(2024, 6, 18), mentor_funding_enabled: false },
  { year: 2022, enabled: false, payments_frozen_at: Time.zone.local(2025, 6, 16), mentor_funding_enabled: false },
  { year: 2023, enabled: true, mentor_funding_enabled: false },
  { year: 2024, enabled: true, mentor_funding_enabled: false },
  { year: 2025, enabled: true, mentor_funding_enabled: true },
  { year: 2026, enabled: false, mentor_funding_enabled: true }
].each do |data|
  FactoryBot.create(:contract_period,
                    year: data[:year],
                    enabled: data[:enabled],
                    payments_frozen_at: data[:payments_frozen_at],
                    mentor_funding_enabled: data[:mentor_funding_enabled]).tap { |cp| describe_contract_period(cp) }
end
