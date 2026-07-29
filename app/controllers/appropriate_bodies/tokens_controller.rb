module AppropriateBodies
  class TokensController < AppropriateBodiesController
    layout "full", only: :index

    def index
      @tokens = API::Token.appropriate_body_period_tokens.where(appropriate_body_period: @appropriate_body)
    end

    def new
    end

    def create
      ActiveRecord::Base.transaction do
        api_token = API::TokenManager.create_appropriate_body_api_token!(
          appropriate_body_period: @appropriate_body,
          api_third_party:
        )

        delivery = API::TokenDelivery.create!(
          api_token:,
          expires_at: 1.hour.from_now
        )

        APITokenDeliveryMailer.with(
          recipient_name: api_third_party.name,
          recipient_email: api_third_party.email,
          token_url: api_token_delivery_url(delivery.token)
        ).api_token_email.deliver_later

        redirect_to ab_tokens_path, notice: "#{api_third_party.name} has been notified (#{api_token.token})"
      end
    end

  private

    def token_params
      params.expect(api_token: :api_third_party_id)
    end

    def api_third_party
      API::ThirdParty.find(token_params[:api_third_party_id])
    end
  end
end
