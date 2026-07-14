# Generate API tokens for Appropriate bodies and their nominated third-party
# Send the third-party an ephemeral link to retrieve to the token
#
Rails.application.routes.default_url_options = { host: "localhost", port: "3000" } if Rails.env.development?

# Fixed deadline of Noon tomorrow
expires_at = Time.zone.now.next_day.change(hour: 12)

ActiveRecord::Base.transaction do
  [
    { third_party: "ECT Manager", appropriate_body: "Umber Teaching School Hub" },
    { third_party: "Mozaic", appropriate_body: "Golden Leaf Teaching School Hub" }
    # { third_party: "Mozaic", appropriate_body: "" },
    # { third_party: "Mozaic", appropriate_body: "" },
    # { third_party: "Mozaic", appropriate_body: "" },
  ].each do |nomination|
    appropriate_body_period = AppropriateBodyPeriod.find_by(name: nomination[:appropriate_body])
    api_third_party = API::ThirdParty.find_by(name: nomination[:third_party])
    api_token = API::TokenManager.create_appropriate_body_api_token!(appropriate_body_period:, api_third_party:)
    delivery = API::TokenDelivery.create!(api_token:, expires_at:)

    APITokenDeliveryMailer.with(
      recipient_name: api_third_party.name,
      recipient_email: api_third_party.email,
      token_url: Rails.application.routes.url_helpers.api_token_delivery_url(delivery.token)
    ).api_token_email.deliver_later
  end
end
