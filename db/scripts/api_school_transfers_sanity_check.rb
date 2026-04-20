# temporary script to sanity check that a service class refactor has not changed the results
# remove before merging
#
# rubocop:disable Rails/Output
LeadProvider.all.find_each do |lead_provider|
  puts "#{lead_provider.name}:"

  old_query = API::Teachers::SchoolTransfers::QueryOld.new(lead_provider_id: lead_provider.id)
  new_query = API::Teachers::SchoolTransfers::Query.new(lead_provider_id: lead_provider.id)

  participant_ids_before = old_query.school_transfers.reorder(nil).pluck(:api_id)
  participant_ids_after = new_query.school_transfers.reorder(nil).pluck(:api_id)

  mismatch = Set.new(participant_ids_before) ^ Set.new(participant_ids_after)

  puts "    Contents: #{mismatch.empty?}"
  puts "    Count:    #{participant_ids_before.size == participant_ids_after.size}"
  puts "    Order:    #{participant_ids_before == participant_ids_after}"
  puts ""
end
# rubocop:enable Rails/Output
