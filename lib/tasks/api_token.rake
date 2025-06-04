namespace :api_token do
  namespace :lead_provider do
    desc "Generate a new API token for the Lead Providers API"
    task :generate_token, %i[lead_provider_name_or_id] => :environment do |_t, args|
      logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

      lead_provider_name_or_id = args.lead_provider_name_or_id

      lead_provider = LeadProvider.find_by(id: lead_provider_name_or_id) || LeadProvider.find_by(name: lead_provider_name_or_id)
      raise("LeadProvider not found") unless lead_provider

      api_token = API::TokenManager.create_lead_provider_api_token!(lead_provider:)

      logger.info "API Token created: #{api_token.token} for Lead provider: #{lead_provider.name}"
      logger.info "** Important: API Tokens should only be transferred via Galaxkey **"
    end
  end
end
