class API::OAuth::Authorization < ApplicationRecord
  include ExpirableCredentials

  enum :code_challenge_method, { s256: "S256" }, validate: true

  belongs_to :client
  belongs_to :appropriate_body_period

  validates :client, :appropriate_body_period, presence: true
  validates :redirect_uri, presence: true, inclusion: { in: -> { it.client.redirect_uris }, allow_blank: true, if: :client, on: :create }
  validates :code_challenge, presence: true

  def error_messages_description = errors.full_messages.join(", ")
end
