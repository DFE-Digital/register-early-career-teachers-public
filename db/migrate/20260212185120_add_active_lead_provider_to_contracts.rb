class AddActiveLeadProviderToContracts < ActiveRecord::Migration[8.0]
  def change
    add_reference :contracts, :active_lead_provider, foreign_key: true
  end
end
