class AddCpdLeadProviderIdToLeadProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :lead_providers, :ecf_cpd_lead_provider_id, :uuid, null: true
  end
end
