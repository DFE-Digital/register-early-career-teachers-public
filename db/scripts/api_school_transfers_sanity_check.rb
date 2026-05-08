# temporary script to sanity check that a service class refactor has not changed the results
# remove before merging
#
# rubocop:disable Rails/Output
LeadProvider.all.find_each do |lead_provider|
  puts "#{lead_provider.name}:"

  lead_provider_id = lead_provider.id

  old_query = API::Teachers::SchoolTransfers::QueryOld.new(lead_provider_id:)
  new_query = API::Teachers::SchoolTransfers::Query.new(lead_provider_id:)

  participant_ids_before = old_query.school_transfers.reorder(nil).pluck(:api_id)
  participant_ids_after = new_query.school_transfers.reorder(nil).pluck(:api_id)

  mismatch = Set.new(participant_ids_before) ^ Set.new(participant_ids_after)
  puts "  Unfiltered:"
  puts "    Contents: #{mismatch.empty?}"
  puts "    Count:    #{participant_ids_before.size == participant_ids_after.size}"
  puts "    Order:    #{participant_ids_before == participant_ids_after}"
  puts ""

  updated_since = 1.month.ago
  old_query_filtered = API::Teachers::SchoolTransfers::QueryOld.new(lead_provider_id:, updated_since:)
  new_query_filtered = API::Teachers::SchoolTransfers::Query.new(lead_provider_id:, updated_since:)

  participant_ids_before = old_query_filtered.school_transfers.reorder(nil).pluck(:api_id)
  participant_ids_after = new_query_filtered.school_transfers.reorder(nil).pluck(:api_id)

  mismatch = Set.new(participant_ids_before) ^ Set.new(participant_ids_after)
  puts "  Filtered: (1 month)"
  puts "    Contents: #{mismatch.empty?}"
  puts "    Count:    #{participant_ids_before.size == participant_ids_after.size}"
  puts "    Order:    #{participant_ids_before == participant_ids_after}"
  puts ""
end
# rubocop:enable Rails/Output
