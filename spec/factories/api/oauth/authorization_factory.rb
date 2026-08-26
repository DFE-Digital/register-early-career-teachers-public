FactoryBot.define do
  factory(:api_oauth_authorization, class: "API::OAuth::Authorization") do
    association :client, factory: :api_oauth_client
    appropriate_body_period
    redirect_uri { client.redirect_uris.first }
    code_challenge { Base64.urlsafe_encode64(Digest::SHA256.digest(SecureRandom.base58(64)), padding: false) }
    code_challenge_method { :s256 }

    after(:build, &:assign_code)
  end
end
