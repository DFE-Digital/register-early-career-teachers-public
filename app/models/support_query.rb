class SupportQuery < ApplicationRecord
  validates :name, presence: true
  validates :email, notify_email: true
  validates :school_name, presence: true
  validates :school_urn, numericality: { only_integer: true }
  validates :message, presence: { message: "Enter your message" }

  state_machine :state, initial: :pending do
    state :pending
    state :sending
    state :sent
    state :failed

    event :mark_as_sending do
      transition pending: :sending
    end

    event :mark_as_sent do
      transition sending: :sent
    end

    event :mark_as_failed do
      transition sending: :failed
    end

    event :reset do
      transition failed: :pending
    end
  end

  def send_to_zendesk_now
    mark_as_sending!

    ticket = zendesk.tickets.create!(
      requester: { name:, email: },
      description:,
      tags: %w[rect-web-form-support-query]
    )

    update!(zendesk_id: ticket.id)

    mark_as_sent!
  rescue StandardError => e
    mark_as_failed!
    raise e
  end

  def send_to_zendesk_later
    SendToZendeskJob.perform_later(self)
  end

private

  def description
    <<~DESCRIPTION
      #{message}

      ---

      School name: #{school_name}
      School URN: #{school_urn}
    DESCRIPTION
  end

  def zendesk
    @zendesk ||= ZendeskAPI::Client.new do |config|
      config.url = ENV.fetch("ZENDESK_URL")
      config.username = ENV.fetch("ZENDESK_USERNAME")
      config.token = ENV.fetch("ZENDESK_TOKEN")
      config.raise_error_when_rate_limited = true
    end
  end
end
