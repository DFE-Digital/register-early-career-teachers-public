module ParityCheck
  class TokenProvider
    class UnsupportedEnvironmentError < RuntimeError; end

    def generate!
      raise UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment" unless enabled?

      known_tokens_by_lead_provider_api_id.each do |api_id, token|
        lead_provider = LeadProvider.find_by(api_id:)
        API::TokenManager.create_lead_provider_api_token!(lead_provider:, token:) if lead_provider
      end
    end

  private

    def known_tokens_by_lead_provider_api_id
      JSON.parse(raw_tokens) || {}
    rescue JSON::ParserError
      {}
    end

    def raw_tokens
      Rails.application.config.parity_check[:tokens]
    end

    def enabled?
      Rails.application.config.parity_check[:enabled]
    end
  end
end
