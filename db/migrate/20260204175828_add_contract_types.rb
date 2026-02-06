class AddContractTypes < ActiveRecord::Migration[8.0]
  def change
    create_enum "contract_types", %w[
      ecf
      ittecf_ectp
    ]
  end
end
