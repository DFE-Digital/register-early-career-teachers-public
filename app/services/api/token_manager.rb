module API
  class TokenManager
    class << self
      # @param lead_provider [LeadProvider]
      # @param token [String]
      # @param description [String]
      # @return [API::Token]
      def create_lead_provider_api_token!(lead_provider:, token: nil, description: nil)
        ActiveRecord::Base.transaction do
          description = "A lead provider token for #{lead_provider.name}" if description.nil?

          Token.create!(lead_provider:, token:, description:).tap do |api_token|
            Events::Record.record_lead_provider_api_token_created_event!(
              author: Events::SystemAuthor.new,
              api_token:
            )
          end
        end
      end

      # @param api_token [API::Token]
      # @return [API::Token]
      def revoke_lead_provider_api_token!(api_token:)
        ActiveRecord::Base.transaction do
          Events::Record.record_lead_provider_api_token_revoked_event!(
            author: Events::SystemAuthor.new,
            api_token:
          )
          api_token.destroy!
        end
      end

      # @param token [String]
      # @return [API::Token]
      def find_lead_provider_api_token(token:)
        Token.lead_provider_tokens.find_by(token:).tap do |api_token|
          api_token&.touch(:last_used_at)
        end
      end

      # @param appropriate_body_period [AppropriateBodyPeriod]
      # @param api_third_party [API::ThirdParty]
      # @param token [String]
      # @param description [String]
      # @return [API::Token]
      def create_appropriate_body_api_token!(appropriate_body_period:, api_third_party:, token: nil, description: nil)
        ActiveRecord::Base.transaction do
          description = "An appropriate body token for #{appropriate_body_period.name} granted to #{api_third_party.name}" if description.nil?

          Token.create!(appropriate_body_period:, token:, description:, api_third_party:).tap do |api_token|
            Events::Record.record_appropriate_body_api_token_created_event!(
              author: Events::SystemAuthor.new,
              api_token:,
              api_third_party:
            )
          end
        end
      end

      # @param api_token [API::Token]
      # @return [API::Token]
      def revoke_appropriate_body_api_token!(api_token:)
        ActiveRecord::Base.transaction do
          Events::Record.record_appropriate_body_api_token_revoked_event!(
            author: Events::SystemAuthor.new,
            api_token:
          )
          api_token.destroy!
        end
      end

      # @param token [String]
      # @return [API::Token]
      def find_appropriate_body_api_token(token:)
        Token.appropriate_body_period_tokens.find_by(token:).tap do |api_token|
          api_token&.touch(:last_used_at)
        end
      end
    end
  end
end
