def describe_api_token(lead_provider_name, token)
  print_seed_info("#{lead_provider_name} \t '#{token}'", indent: 2)
end

maximum_lead_provider_name_length = LeadProvider.maximum("LENGTH(name)")

LeadProvider.find_each do |lead_provider|
  token = lead_provider.name.parameterize
  API::TokenManager.create_lead_provider_api_token!(lead_provider:, token:)

  lead_provider_name = lead_provider.name.ljust(maximum_lead_provider_name_length)
  describe_api_token(lead_provider_name, token)
end
