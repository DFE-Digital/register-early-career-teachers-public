constraints -> { Rails.application.config.enable_api_test_client } do
  namespace :integration_support, path: "integration-support" do
    resource :api_client_connection, only: %i[new create show update], path: "api-client-connection"
  end
end
