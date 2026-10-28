class AddShortNameToLeadProviders < ActiveRecord::Migration[8.1]
  def up
    add_column :lead_providers, :short_name, :string

    short_names = {
      "Ambition Institute" => "ambition",
      "Best Practice Network" => "bpn",
      "Capita" => "capita",
      "Education Development Trust" => "edt",
      "National Institute of Teaching" => "niot",
      "Teach First" => "tf",
      "UCL Institute of Education" => "ucl",
      # Staging lead providers
      "Reuse – Lead Provider One" => "reuse",
      "Reuse – Lead Provider X (not available in target year)" => "reusex"
    }

    LeadProvider.find_each do |lead_provider|
      lead_provider.update!(short_name: short_names.fetch(lead_provider.name))
    end

    change_column_null :lead_providers, :short_name, false
    add_index :lead_providers, :short_name, unique: true
  end

  def down
    remove_index :lead_providers, :short_name
    remove_column :lead_providers, :short_name
  end
end
