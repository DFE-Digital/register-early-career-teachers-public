namespace :api_token do
  namespace :lead_provider do
    desc "Generate a new API token for the Lead Providers API"
    task :generate_token, %i[lead_provider_name_or_id] => :environment do |_t, args|
      logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

      API::AddAPITokenToLeadProvider.new(
        lead_provider_name_or_id: args.lead_provider_name_or_id,
        logger:
      ).add

      logger.info "** Important: API Tokens should only be transferred via Galaxkey **"
    end
  end
end
