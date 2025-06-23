Blueprinter.configure do |config|
  config.generator = Oj
  config.datetime_format = ->(datetime) { datetime&.utc&.rfc3339 }
  config.sort_fields_by = :definition
end
