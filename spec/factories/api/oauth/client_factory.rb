FactoryBot.define do
  factory(:api_oauth_client, class: "API::OAuth::Client") do
    sequence(:name) { |n| "Vendor #{n}" }
    redirect_uris { %w[https://vendor.com/oauth/callback] }
  end
end
