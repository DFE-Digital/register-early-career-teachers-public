class AddActiveLeadProviderAndLeadProviderDeliveryPartnershipRelationshipsToEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :events, :active_lead_provider, index: true, null: true, foreign_key: { on_delete: :nullify }
    add_reference :events, :lead_provider_delivery_partnership, index: true, null: true, foreign_key: { on_delete: :nullify }
  end
end
