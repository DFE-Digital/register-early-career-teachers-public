class RenameActiveLeadProvidersToFrameworkAgreements < ActiveRecord::Migration[8.1]
  def change
    rename_table :active_lead_providers, :framework_agreements
    rename_table :active_lead_provider_bands, :framework_agreement_bands

    rename_column :framework_agreement_bands, :active_lead_provider_id, :framework_agreement_id
    rename_column :contracts, :active_lead_provider_id, :framework_agreement_id
    rename_column :events, :active_lead_provider_id, :framework_agreement_id
    rename_column :lead_provider_delivery_partnerships, :active_lead_provider_id, :framework_agreement_id

    rename_index :lead_provider_delivery_partnerships, :idx_lpdps_active_lead_provider, :idx_lpdps_framework_agreement
  end
end
