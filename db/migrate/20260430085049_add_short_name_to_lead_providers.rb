class AddShortNameToLeadProviders < ActiveRecord::Migration[8.1]
  def up
    add_column :lead_providers, :short_name, :string, null: true

    short_names = {
      "Ambition Institute" => "ambition",
      "Best Practice Network" => "bpn",
      "Capita" => "capita",
      "Education Development Trust" => "edt",
      "National Institute of Teaching" => "niot",
      "Teach First" => "tf",
      "UCL Institute of Education" => "ucl",
    }

    unknown_short_names = LeadProvider.where.not(name: short_names.keys).pluck(:name)

    if unknown_short_names.any?
      raise ActiveRecord::MigrationError,
            "Missing short_names for: #{unknown_short_names.join(', ')}"
    end

    LeadProvider.find_each do |lead_provider|
      lead_provider.update!(short_name: short_names[lead_provider.name])
    end
  end

  def down
    remove_column :lead_providers, :short_name
  end
end
