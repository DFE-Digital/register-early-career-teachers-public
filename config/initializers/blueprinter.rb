Blueprinter.configure do |config|
  config.generator = Oj
  config.datetime_format = ->(date_or_time) { date_or_time.is_a?(Date) ? date_or_time.to_fs(:api) : date_or_time&.utc&.rfc3339 }
  config.sort_fields_by = :definition
end
