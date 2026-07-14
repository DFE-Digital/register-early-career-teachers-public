module API
  class TokenDeliveriesController < ApplicationController
    # single‑use / time‑bound
    def show
      delivery = TokenDelivery.find_by!(token: params[:token])

      if delivery.unused? && delivery.extant?
        delivery.update!(used_at: Time.current)
        render plain: delivery.api_token.token, content_type: "text/plain"
      else
        head :gone
      end
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end
  end
end
