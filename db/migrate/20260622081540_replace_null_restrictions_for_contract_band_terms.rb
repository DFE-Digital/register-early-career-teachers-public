class ReplaceNullRestrictionsForContractBandTerms < ActiveRecord::Migration[8.1]
  # rubocop:disable Rails/BulkChangeTable
  def change
    change_column_null :contract_banded_fee_structure_band_terms, :band_id, false
    change_column_null :contract_banded_fee_structure_band_terms, :max_declarations, true
  end
  # rubocop:enable Rails/BulkChangeTable
end
