class APITokenDeliveryMailer < ApplicationMailer
  def api_token_email
    to = params.fetch(:recipient_email)
    @recipient_name = params.fetch(:recipient_name)
    @token_url = params.fetch(:token_url)

    view_mail(NOTIFY_TEMPLATE_ID, to:, subject: "You have been granted access")
  end
end
