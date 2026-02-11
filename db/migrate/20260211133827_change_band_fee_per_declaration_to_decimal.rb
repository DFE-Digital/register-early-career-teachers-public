class ChangeBandFeePerDeclarationToDecimal < ActiveRecord::Migration[8.0]
  def up
    change_column :contract_banded_fee_structure_bands, :fee_per_declaration, :decimal, precision: 12, scale: 2
  end

  def down
    change_column :contract_banded_fee_structure_bands, :fee_per_declaration, :integer
  end
end
