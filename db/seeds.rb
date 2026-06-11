Rails.root.glob("db/seeds/support/{*.rb,teacher_histories/*.rb,builders/*.rb}").each { require(it) }

priority_seeds = %w[
  contract_periods
  lead_providers
  appropriate_body_periods
  delivery_partners
  schools
  gias_data
  lead_provider_delivery_partnerships
  school_partnerships
  schedules_and_milestones
  teachers
  contracts
  statements
  bulk_uploads
]

ActiveJob::Base.queue_adapter = :inline

seed_files = Dir["db/seeds/*.rb"].sort_by do |path|
  filename = File.basename(path)
  priority_seeds.index(filename.chomp(".rb")) || Float::INFINITY
end

DeclarativeUpdates.skip(:metadata) do
  seed_files.each do |seed_file|
    puts "\r\n🪴 planting #{seed_file}"

    ApplicationRecord.transaction { load(seed_file) }
  end
end

# Refresh all metadata
Metadata::Manager.refresh_all_metadata!(async: false, track_changes: false)
