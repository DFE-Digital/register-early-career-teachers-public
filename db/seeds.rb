def print_seed_info(text, indent: 0, colour: nil, blank_lines_before: 0)
  blank_lines_before.times { puts "🌱 \n" }

  if colour
    puts "🌱 " + (" " * indent) + Colourize.text(text, colour)
  else
    puts "🌱 " + (" " * indent) + text
  end
end

priority_seeds = %w[
  contract_periods
  lead_providers
  appropriate_bodies
  delivery_partners
  schools
  lead_provider_delivery_partnerships
  school_partnerships
  schedules_and_milestones
  teachers
  metadata
]

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
