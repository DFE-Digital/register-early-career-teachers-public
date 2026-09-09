def describe_api_oauth_client(client, client_secret)
  client_id = Colourize.text(client.client_id, :yellow)

  print_seed_info("#{client.name} (#{client_id})", indent: 2)
  print_seed_info("🔑 Secret: #{client_secret}", indent: 4)
end

service_url = ENV.fetch("SERVICE_URL", "http://localhost:3000")

client = FactoryBot.create(
  :api_oauth_client,
  name: "OAuth test client",
  client_id: IntegrationSupport::APIClientConnection::SEED_CLIENT_ID,
  client_secret_digest: Digest::SHA256.hexdigest(IntegrationSupport::APIClientConnection::SEED_CLIENT_SECRET),
  redirect_uris: [Rails.application.routes.url_helpers.integration_support_api_client_connection_url(host: service_url)]
)

describe_api_oauth_client(client, IntegrationSupport::APIClientConnection::SEED_CLIENT_SECRET)
