def describe_registration_period(ay)
  print_seed_info("#{ay.year} (running from #{ay.started_on} until #{ay.finished_on})", indent: 2)
end

{
  2021 => false,
  2022 => false,
  2023 => true,
  2024 => true,
  2025 => true
}.each do |year, enabled|
  RegistrationPeriod.create!(
    year:,
    started_on: Date.new(year, 6, 1),
    finished_on: Date.new(year + 1, 5, 31),
    enabled:
  ).tap { |rp| describe_registration_period(rp) }
end
