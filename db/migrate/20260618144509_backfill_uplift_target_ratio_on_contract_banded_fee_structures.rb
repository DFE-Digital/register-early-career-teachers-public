class BackfillUpliftTargetRatioOnContractBandedFeeStructures < ActiveRecord::Migration[8.1]
  UPLIFT_TARGET_RATIOS_BY_YEAR = {
    2021 => 0.33,
    2022 => 0.33,
    2023 => 0.33,
    2024 => 0.4,
    2025 => 0.0
  }.freeze

  def up
    UPLIFT_TARGET_RATIOS_BY_YEAR.each do |year, uplift_target_ratio|
      Contract::BandedFeeStructure
        .joins(contract: :active_lead_provider)
        .where(active_lead_providers: { contract_period_year: year })
        .where(contracts: { contract_type: "ecf" })
        .update_all(uplift_target_ratio:)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "The original uplift target ratio values cannot be restored"
  end
end
