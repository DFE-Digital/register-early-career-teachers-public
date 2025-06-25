class AddFeeTypesAndReplaceOutputFee < ActiveRecord::Migration[8.0]
  def change
    create_enum 'fee_types', %w[output service]

    change_table :statements, bulk: true do |t|
      t.remove :output_fee, type: :boolean, default: true, null: false
      t.column :fee_type, :enum, enum_type: 'fee_types', default: 'output', null: false
    end
  end
end
