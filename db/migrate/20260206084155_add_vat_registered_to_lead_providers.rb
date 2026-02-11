class AddVATRegisteredToLeadProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :lead_providers, :vat_registered, :boolean, default: true, null: false
  end
end
