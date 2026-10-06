class RemoveServiceFeeProportionFromBandTerms < ActiveRecord::Migration[8.0]
  def change
    remove_column :contract_banded_fee_structure_band_terms,
                  :service_fee_proportion,
                  :decimal,
                  precision: 3,
                  scale: 2,
                  null: false
  end
end
