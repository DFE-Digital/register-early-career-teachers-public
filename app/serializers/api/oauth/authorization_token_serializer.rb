class API::OAuth::AuthorizationTokenSerializer < Blueprinter::Base
  field :access_token

  field :expires_in do |data|
    (data[:token_expires_at] - Time.zone.now).round
  end

  field :token_type do
    "Bearer"
  end
end
