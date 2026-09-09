module IntegrationSupport
  class APIClientConnectionsController < ApplicationController
    layout "integration_support"

    before_action :resume_api_client_connection, only: %i[show update]

    def new
      @api_client_connection = APIClientConnection.new(redirect_uri: integration_support_api_client_connection_url)
    end

    def create
      @api_client_connection = APIClientConnection.new(api_client_connection_params)

      @api_client_connection.store_in(session)
      redirect_to(oauth_authorization_path(@api_client_connection.authorize_params))
    end

    def show
      @api_client_connection.assign_callback(params.permit(:code, :state, :error, :error_description))
      @api_client_connection.store_in(session)
    end

    def update
      @api_client_connection.assign_attributes(api_client_connections_update_params)
      @api_client_connection.store_in(session)

      @response = @api_client_connection.exchange_code_for_token(oauth_authorization_token_url)
    rescue Faraday::Error => e
      @request_error = e.message
    end

  private

    def resume_api_client_connection
      @api_client_connection = APIClientConnection.from(session)

      render(:missing_connection, status: :bad_request) if @api_client_connection.blank?
    end

    def api_client_connection_params
      params.expect(
        integration_support_api_client_connection: %i[
          appropriate_body_period_id
          redirect_uri
          client_id
          client_secret
          code_verifier
          code_challenge
          code_challenge_method
          state
        ]
      )
    end

    def api_client_connections_update_params
      params.expect(
        integration_support_api_client_connection: %i[client_id client_secret grant_type code code_verifier redirect_uri]
      )
    end
  end
end
