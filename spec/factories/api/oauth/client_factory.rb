FactoryBot.define do
  factory(:api_oauth_client, class: "API::OAuth::Client") do
    sequence(:name) { |n| "Vendor #{n}" }
    redirect_uris { %w[https://vendor.com/oauth/callback] }
    grant_types { %w[authorization_code] }
  end
end
