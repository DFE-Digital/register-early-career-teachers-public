module IntegrationSupport
  class APIClientsController < AdminController
    layout "integration_support"

    def new
      @client = API::OAuth::Client.new(client_id: "client-#{API::OAuth::Client.maximum(:id).to_i + 1}")
      @client_secret = APIClientConnection::DEFAULT_CLIENT_SECRET
    end

    def create
      @client_secret = client_params[:client_secret]
      @client = API::OAuth::Client.new(
        name: client_params[:name],
        client_id: client_params[:client_id],
        client_secret_digest: Digest::SHA256.hexdigest(@client_secret.to_s),
        redirect_uris: [integration_support_api_client_connection_url],
        grant_types: API::OAuth::Client::GRANT_TYPES
      )

      if @client.save
        redirect_to(new_integration_support_api_client_connection_path(client_id: @client.client_id))
      else
        render(:new, status: :unprocessable_content)
      end
    end

  private

    def authorised? = super && current_user.admin?

    def client_params
      params.expect(api_oauth_client: %i[name client_id client_secret])
    end
  end
end
