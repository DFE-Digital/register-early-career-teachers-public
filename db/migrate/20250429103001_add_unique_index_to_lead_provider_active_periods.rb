class AddUniqueIndexToLeadProviderActivePeriods < ActiveRecord::Migration[8.0]
  def change
    add_index :lead_provider_active_periods, %i[registration_period_id lead_provider_id], unique: true
  end
end
