class CreateLeadProviderActivePeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :lead_provider_active_periods do |t|
      t.references :lead_provider, null: false, foreign_key: true
      t.references :registration_period, null: false, foreign_key: { primary_key: :year }

      t.timestamps
    end
  end
end
