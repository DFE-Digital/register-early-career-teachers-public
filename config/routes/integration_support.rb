constraints -> { Rails.application.config.enable_api_test_client } do
  namespace :integration_support, path: "integration-support" do
    resources :api_clients, only: %i[new create], path: "api-clients"
    resource :api_client_connection, only: %i[new create show update destroy], path: "api-client-connection" do
      get :delete
    end
  end
end
