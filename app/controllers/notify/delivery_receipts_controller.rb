module Notify
  class DeliveryReceiptsController < ActionController::API
    include Notify::TokenAuthenticable

    def create
      delivery_receipt = Notify::DeliveryReceipt.new(delivery_receipt_attributes)

      if delivery_receipt.save
        head :created
      else
        log_error("Failed to save delivery receipt", delivery_receipt.errors.messages)
        render json: { errors: delivery_receipt.errors.messages }, status: :unprocessable_content
      end
    end

  private

    def delivery_receipt_attributes
      payload = params.permit(
        :id,
        :reference,
        :to,
        :status,
        :created_at,
        :completed_at,
        :sent_at,
        :notification_type,
        :template_id,
        :template_version
      )

      {
        notification_id: payload[:id],
        recipient: payload[:to],
        status: payload[:status],
        requested_at: payload[:created_at],
        completed_at: payload[:completed_at],
        sent_at: payload[:sent_at],
        notification_type: payload[:notification_type],
        template_id: payload[:template_id],
        template_version: payload[:template_version],
      }
    end

    def log_error(description, errors)
      Sentry.with_scope do |scope|
        scope.set_context("errors", errors) if scope
        Sentry.capture_message(description)
      end
    end
  end
end
