# Generic data fixing handler to fix migrated data issues
# will read migration_data_fixes.csv and process contents
#
# CSV should have the following columns:
# object_type - the ruby class of the DB record
# object_id   - the primary key of the record to modify (ignored for create actions)
# action      - the action to perform create|update|delete
# attributes  - a comma separated list of attribute name and value pairs in the format "attrname_1,value_1,attrname_2,value_2".
#               Ensure the list is enclosed in quotes so the CSV sees just a single data field
#
# $ kubectl exec -it <pod-name> -- bin/rails runner db/scripts/migration_data_fixes.rb
csv_log = nil

begin
  update_readonly_attrs = ENV["UPDATE_READONLY_ATTRS"].present?

  csv_file = Rails.root.join("db/scripts/migration_data_fixes.csv")
  csv_log = CSV.open(Rails.root.join("tmp/migration_data_fixes_log-#{Time.zone.now.to_fs(:iso8601)}.csv"), "w")
  csv_log << %w[object_type object_id action attributes errors]
  processor = Admin::DataFixes::Processor.new(update_readonly_attrs:)

  CSV.foreach(csv_file, headers: true, header_converters: :symbol) do |row|
    result = processor.process!(data_change: row.to_h)
    error = result.error

    if error
      Rails.logger.warn(
        "ERROR processing #{row[:object_type]} ID #{row[:object_id]}: " \
        "#{error.class} - #{error.message}"
      )
    end

    csv_log << [
      row[:object_type],
      row[:object_id],
      row[:action],
      row[:attributes],
      error&.message,
    ]
  end
ensure
  csv_log&.close
end
