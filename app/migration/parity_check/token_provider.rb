module ParityCheck
  class TokenProvider
    include ParityCheck::Configuration

    def generate!
      ensure_parity_check_enabled!

      known_tokens_by_lead_provider_ecf_id.each do |ecf_id, token|
        lead_provider = LeadProvider.find_by(ecf_id:)
        API::TokenManager.create_lead_provider_api_token!(lead_provider:, token:) if lead_provider
      end
    end

    def token(lead_provider:)
      ensure_parity_check_enabled!

      known_tokens_by_lead_provider_ecf_id.fetch(lead_provider.ecf_id)
    end

  private

    def known_tokens_by_lead_provider_ecf_id
      JSON.parse(parity_check_tokens) || {}
    rescue JSON::ParserError
      {}
    end
  end
end
