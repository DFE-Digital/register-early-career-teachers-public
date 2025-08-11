Rails.application.eager_load!

Metadata::Manager.refresh_all_metadata!

Metadata::Base.descendants.each do |metadata_class|
  count = ActionController::Base.helpers.number_with_delimiter(metadata_class.count)
  print_seed_info("#{metadata_class.name} - #{count} records", indent: 2)
end
