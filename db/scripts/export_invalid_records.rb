# 🫠 Wonkiness checker (use on production data but not on the production deployment)
#
# Example:
#   rails runner db/scripts/export_invalid_records.rb induction_periods induction_extensions
#
# Run in-service model validations to help triage data

if Rails.env.production?
  $stdout.puts "Query production data using a database backup."
  exit 0
end

if ARGV.empty?
  $stdout.puts "No tables specified."
  exit 0
end

batch_size = 1_000
headers = %w[table_name record_id errors]
date = Time.zone.today.iso8601
filename = Rails.root.join("tmp", "invalid-records-#{date}.csv")
results = []

def validate(model, batch_size, &block)
  model.find_in_batches(batch_size:) do |batch|
    batch.each(&block)
  end
end

ARGV.each do |table_name|
  model = table_name.singularize.camelize.constantize

  validate(model, batch_size) do |record|
    next if record.valid?

    errors = record.errors.full_messages.join("; ")

    results << {
      table_name: model.table_name,
      record_id: record.id,
      errors:,
    }
  end
end

if results.empty?
  $stdout.puts "No invalid records found."
  exit 0
end

CSV.open(filename, "w", write_headers: true, headers:) do |csv|
  results.each { |row| csv << row.values }
end

$stdout.puts "Exported #{results.size} invalid record(s) to #{filename}"
