class AddDetailedEvidenceTypesToContractPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :contract_periods, :detailed_evidence_types_enabled, :boolean, null: false, default: false
  end
end
