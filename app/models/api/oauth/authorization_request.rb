module API
  module OAuth
    class AuthorizationRequest
      include ActiveModel::Model
      include ActiveModel::Attributes
      include SessionStorable
      include Redirectable

      RESPONSE_TYPE = "code"

      attribute :response_type, :string
      attribute :client_id, :string
      attribute :appropriate_body_period_id, :integer
      attribute :redirect_uri, :string
      attribute :code_challenge, :string
      attribute :code_challenge_method, :string
      attribute :state, :string
      attribute :logged_in_appropriate_body_period_id, :integer

      validates :response_type, presence: true
      validates :response_type, inclusion: { in: [RESPONSE_TYPE] }, allow_blank: true
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
    end
  end
end
