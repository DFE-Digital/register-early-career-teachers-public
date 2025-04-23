class CreateActiveLeadProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :active_lead_providers do |t|
      t.references :lead_provider, null: false, foreign_key: true
      t.bigint :registration_period_id, null: false
      t.timestamps
    end

    add_foreign_key :active_lead_providers, :registration_periods, column: :registration_period_id, primary_key: :year
    add_index :active_lead_providers, %i[lead_provider_id registration_period_id], unique: true
  end
end
