class API::OAuth::AuthorizationTokenSerializer < Blueprinter::Base
  field :access_token

  field :expires_in

  field :token_type do
    "Bearer"
  end
end
