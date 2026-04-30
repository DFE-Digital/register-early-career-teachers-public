class AddShortNameToLeadProviders < ActiveRecord::Migration[8.1]
  def up
    add_column :lead_providers, :short_name, :string

    LeadProvider.find_each do |lead_provider|
      lead_provider.update!(short_name: lead_provider.name.split.map(&:first).join)
    end

    change_column_null :lead_providers, :short_name, false
  end

  def down
    remove_column :lead_providers, :short_name
  end
end
