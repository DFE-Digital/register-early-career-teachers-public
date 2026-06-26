class RenameContractBandsToBandTerms < ActiveRecord::Migration[8.1]
  def change
    rename_table :contract_banded_fee_structure_bands, :contract_banded_fee_structure_band_terms
  end
end
