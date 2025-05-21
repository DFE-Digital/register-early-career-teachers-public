def describe_registration_period(ay)
  print_seed_info("#{ay.year} (running from #{ay.started_on} until #{ay.finished_on})", indent: 2)
end

RegistrationPeriod.create!(year: 2021, started_on: Date.new(2021, 6, 1), finished_on: Date.new(2022, 5, 31), enabled: false).tap { |ay| describe_registration_period(ay) }
RegistrationPeriod.create!(year: 2022, started_on: Date.new(2022, 6, 1), finished_on: Date.new(2023, 5, 31), enabled: false).tap { |ay| describe_registration_period(ay) }
RegistrationPeriod.create!(year: 2023, started_on: Date.new(2023, 6, 1), finished_on: Date.new(2024, 5, 31), enabled: true).tap { |ay| describe_registration_period(ay) }
RegistrationPeriod.create!(year: 2024, started_on: Date.new(2024, 6, 1), finished_on: Date.new(2025, 5, 31), enabled: true).tap { |ay| describe_registration_period(ay) }
RegistrationPeriod.create!(year: 2025, started_on: Date.new(2025, 6, 1), finished_on: Date.new(2026, 5, 31), enabled: true).tap { |ay| describe_registration_period(ay) }
