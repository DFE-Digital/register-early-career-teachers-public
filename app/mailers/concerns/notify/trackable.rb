module Notify::Trackable
  extend ActiveSupport::Concern

  included do
    before_deliver :create_outbound,
                   if: -> { Rails.application.config.enable_notify_delivery_receipts }
  end

private

  def create_outbound
    return unless message.reference

    Notify::Outbound.create!(
      reference: message.reference,
      mailer: self.class.name,
      mailer_action: action_name
    )
  rescue StandardError => e
    # This happens *before* an email has been delivered.
    # We never want errors to prevent emails being sent.
    # If we fail to create an Outbound, we won't be able to correlate the
    # delivery receipt —but that's ok.
    Sentry.capture_exception(e)
  end
end
