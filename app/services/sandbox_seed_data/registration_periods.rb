module SandboxSeedData
  class RegistrationPeriods < Base
    DATA = {
      2021 => false,
      2022 => false,
      2023 => true,
      2024 => true,
      2025 => true
    }.freeze

    def plant
      return unless plantable?

      log_plant_info("registration periods")

      DATA.each do |year, enabled|
        RegistrationPeriod.find_or_create_by!(
          year:,
          enabled:,
          started_on: Date.new(year, 6, 1),
          finished_on: Date.new(year + 1, 5, 31)
        ).tap do |registration_period|
          log_seed_info("#{registration_period.year} (running from #{registration_period.started_on} until #{registration_period.finished_on})")
        end
      end
    end
  end
end
