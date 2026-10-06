class RenameRatioColumnsOnContractFeeStructures < ActiveRecord::Migration[8.0]
  def change
    rename_column :contract_banded_fee_structure_band_terms, :output_fee_ratio, :output_fee_proportion
    rename_column :contract_banded_fee_structure_band_terms, :service_fee_ratio, :service_fee_proportion
    rename_column :contract_banded_fee_structures, :uplift_target_ratio, :uplift_target_proportion
  end
end
