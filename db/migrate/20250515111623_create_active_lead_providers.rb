class CreateActiveLeadProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :active_lead_providers do |t|
      t.references :lead_provider, null: false, foreign_key: true
      t.references :registration_period, null: false, foreign_key: { primary_key: :year }

      t.timestamps
    end

    add_index :active_lead_providers, %i[lead_provider_id registration_period_id], unique: true
  end
end
