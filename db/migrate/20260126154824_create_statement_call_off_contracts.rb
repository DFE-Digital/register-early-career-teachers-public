class CreateStatementCallOffContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :statement_call_off_contracts do |t|
      t.references :statement, foreign_key: { to_table: :statements }

      t.integer :recruitment_target
      t.decimal :set_up_fee
      t.decimal :monthly_service_fee

      t.decimal :uplift_target
      t.decimal :uplift_amount

      %i[a b c d].each do |letter|
        t.integer :"band_#{letter}_max", default: 0
        t.decimal :"band_#{letter}_per_participant", default: 0.0
        t.integer :"band_#{letter}_output_payment_percentage", default: 0
        t.integer :"band_#{letter}_service_fee_percentage", default: 0
      end

      t.timestamps
    end
  end
end
