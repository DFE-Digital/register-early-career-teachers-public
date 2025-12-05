module APISeedData
  class APITokens < Base
    def plant
      return unless plantable?

      log_plant_info("api_tokens")

      LeadProvider.find_each do |lead_provider|
        token = lead_provider.name.parameterize

        FactoryBot.create(:api_token,
                          lead_provider:,
                          token:,
                          description: "A lead provider token for #{lead_provider.name}",
                          last_used_at: nil)

        maximum_lead_provider_name_length = LeadProvider.maximum("LENGTH(name)")
        lead_provider_name = lead_provider.name.ljust(maximum_lead_provider_name_length)
        describe_api_token(lead_provider_name, token)
      end
    end

  protected

    def plantable?
      super && API::Token.none?
    end

  private

    def describe_api_token(lead_provider_name, token)
      log_seed_info("#{lead_provider_name} \t '#{token}'", indent: 2)
    end
  end
end
