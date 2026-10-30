class AddShortNameToLeadProviders < ActiveRecord::Migration[8.1]
  def up
    add_column :lead_providers, :short_name, :string

    LeadProvider.find_each do |lead_provider|
      lead_provider.assign_short_name
      lead_provider.save!
    end

    # Specific short names for lead providers that do not
    # follow the standard short name convention.
    short_name_overrides = {
      "Ambition Institute" => "ambition",
    }

    LeadProvider.where(name: short_name_overrides.keys).find_each do |lead_provider|
      lead_provider.update!(short_name: short_name_overrides.fetch(lead_provider.name))
    end

    change_column_null :lead_providers, :short_name, false
    add_index :lead_providers, :short_name, unique: true
  end

  def down
    remove_index :lead_providers, :short_name
    remove_column :lead_providers, :short_name
  end
end
