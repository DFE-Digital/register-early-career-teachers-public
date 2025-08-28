module SandboxSeedData
  class ContractPeriods < Base
    DATA = {
      2021 => false,
      2022 => false,
      2023 => true,
      2024 => true,
      2025 => true
    }.freeze

    def plant
      return unless plantable?

      log_plant_info("contract_periods")

      DATA.each do |year, enabled|
        FactoryBot.create(:contract_period,
                          year:,
                          enabled:).tap do |contract_period|
          log_seed_info("#{contract_period.year} (running from #{contract_period.started_on} until #{contract_period.finished_on})")
        end
      end
    end
  end
end
