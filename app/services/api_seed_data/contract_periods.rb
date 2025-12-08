module APISeedData
  class ContractPeriods < Base
    # Seed contract periods and attributes same as in production
    DATA = [
      { year: 2021,
        enabled: false,
        payments_frozen_at: Time.zone.local(2024, 6, 18),
        mentor_funding_enabled: false,
        detailed_evidence_types_enabled: false },
      { year: 2022,
        enabled: false,
        payments_frozen_at: Time.zone.local(2025, 6, 16),
        mentor_funding_enabled: false,
        detailed_evidence_types_enabled: false },
      { year: 2023,
        enabled: true,
        mentor_funding_enabled: false,
        detailed_evidence_types_enabled: false },
      { year: 2024,
        enabled: true,
        mentor_funding_enabled: false,
        detailed_evidence_types_enabled: false },
      { year: 2025,
        enabled: true,
        mentor_funding_enabled: true,
        detailed_evidence_types_enabled: true },
    ].freeze

    def plant
      return unless plantable?

      log_plant_info("contract_periods")

      DATA.each do |data|
        FactoryBot.create(:contract_period,
                          year: data[:year],
                          enabled: data[:enabled],
                          payments_frozen_at: data[:payments_frozen_at],
                          mentor_funding_enabled: data[:mentor_funding_enabled],
                          detailed_evidence_types_enabled: data[:detailed_evidence_types_enabled]).tap do |contract_period|
          log_seed_info("#{contract_period.year} (running from #{contract_period.started_on} until #{contract_period.finished_on})")
        end
      end
    end

  protected

    def plantable?
      super && ContractPeriod.none?
    end
  end
end
