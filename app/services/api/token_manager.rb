module API
  class TokenManager
    class << self
      def create_lead_provider_api_token!(lead_provider:, token: nil, description: nil)
        description = "A lead provider token for #{lead_provider.name}" if description.nil?

        Token.create!(
          lead_provider:,
          token:,
          description:
        ).tap do |api_token|
          Events::Record.record_lead_provider_api_token_created_event!(author: Events::SystemAuthor.new, api_token:)
        end
      end

      def revoke_lead_provider_api_token!(api_token:)
        api_token.destroy!
        Events::Record.record_lead_provider_api_token_revoked_event!(author: Events::SystemAuthor.new, api_token:)
      end

      def find_lead_provider_api_token(token:)
        Token.lead_provider_tokens.find_by(token:).tap { |api_token| api_token&.touch(:last_used_at) }
      end
    end
  end
end
