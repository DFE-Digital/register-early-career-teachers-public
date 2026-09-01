module API
  module OAuth
    class AuthorizationRequest
      include ActiveModel::Model
      include ActiveModel::Attributes

      RESPONSE_TYPE = "code"

      attribute :response_type, :string
      attribute :client_id, :string
      attribute :appropriate_body_period_id, :integer
      attribute :redirect_uri, :string
      attribute :code_challenge, :string
      attribute :code_challenge_method, :string
      attribute :state, :string
      attribute :logged_in_appropriate_body_period_id, :integer

      validates :response_type, inclusion: { in: [RESPONSE_TYPE] }
      validates :code_challenge, presence: true
      validates :code_challenge_method, inclusion: { in: Authorization.code_challenge_methods.values }
      validates :appropriate_body_period_id, presence: true, comparison: {
        equal_to: :logged_in_appropriate_body_period_id,
        message: "does not match the logged-in Appropriate Body"
      }
      validates :client, presence: true
      validates :redirect_uri, inclusion: { in: ->(request) { request.client.redirect_uris } }, if: :client

      delegate :name, to: :client, prefix: true, allow_nil: true

      def client = @client ||= Client.find_by(client_id:)

      def redirectable? = redirect_uri.present? && client&.redirect_uris&.include?(redirect_uri)

      def error_messages_description = errors.full_messages.join(", ")

      def redirect_uri_with(error:, error_description: error_messages_description)
        uri = URI.parse(redirect_uri)
        existing_query_params = uri.query.present? ? URI.decode_www_form(uri.query).to_h : {}
        error_params = error.present? ? { error:, error_description: } : {}
        state = self.state.present? ? { state: self.state } : {}
        query_params = existing_query_params.merge(error_params).merge(state).compact
        uri.query = URI.encode_www_form(query_params)
        uri.to_s
      end
    end
  end
end
