module IntegrationSupport
  class APIClientConnection
    include ActiveModel::Model
    include ActiveModel::Attributes

    SESSION_KEY = :api_client_connection
    SEED_CLIENT_ID = "test-client-id"
    SEED_CLIENT_SECRET = "test-client-secret"
    TOKEN_REQUEST_TIMEOUT = 5

    AUTHORIZE_PARAMS = %i[
      response_type
      client_id
      appropriate_body_period_id
      redirect_uri
      code_challenge
      code_challenge_method
      state
    ].freeze

    attribute :response_type, :string, default: -> { API::OAuth::AuthorizationRequest::RESPONSE_TYPE }
    attribute :appropriate_body_period_id, :integer
    attribute :redirect_uri, :string
    attribute :client_id, :string, default: SEED_CLIENT_ID
    attribute :client_secret, :string, default: SEED_CLIENT_SECRET
    attribute :code_verifier, :string, default: -> { SecureRandom.base58(64) }
    attribute :code_challenge, :string
    attribute :code_challenge_method, :string, default: -> { API::OAuth::Authorization.code_challenge_methods.values.first }
    attribute :state, :string, default: -> { SecureRandom.uuid }
    attribute :grant_type, :string, default: -> { API::OAuth::Client::GRANT_TYPES.first }
    attribute :code, :string
    attribute :returned_state, :string
    attribute :error, :string
    attribute :error_description, :string

    class << self
      def from(session)
        return if session[SESSION_KEY].blank?

        new(session[SESSION_KEY])
      end

      def code_challenge_for(code_verifier)
        Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier.to_s), padding: false)
      end
    end

    def store_in(session) = session[SESSION_KEY] = attributes

    def code_challenge = super || self.class.code_challenge_for(code_verifier)

    def authorize_params = AUTHORIZE_PARAMS.index_with { public_send(it) }

    def assign_callback(callback_params)
      assign_attributes(
        code: callback_params[:code],
        returned_state: callback_params[:state],
        error: callback_params[:error],
        error_description: callback_params[:error_description]
      )
    end

    def authorization_denied? = error.present?
    def state_mismatch? = returned_state.present? && returned_state != state

    def exchange_code_for_token(token_url)
      connection.post(token_url, { grant_type:, code:, code_verifier:, redirect_uri: })
    end

  private

    def connection
      @connection ||= Faraday.new(request: { timeout: TOKEN_REQUEST_TIMEOUT }) do |faraday|
        faraday.request(:url_encoded)
        faraday.request(:authorization, :basic, client_id.to_s, client_secret.to_s)
        faraday.response(:json, content_type: /\bjson$/)
      end
    end
  end
end
