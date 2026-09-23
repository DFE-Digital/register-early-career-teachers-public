class API::OAuth::Authorization < ApplicationRecord
  include ExpirableCredentials
  include Revocable

  enum :code_challenge_method, { s256: "S256" }, validate: true

  belongs_to :client
  belongs_to :appropriate_body_period

  validates :client, :appropriate_body_period, presence: true
  validates :redirect_uri, presence: true, inclusion: { in: -> { it.client.redirect_uris }, allow_blank: true, if: :client, on: :create }
  validates :code_challenge, presence: true
  validate :only_one_active_authorization, if: :active?

  scope :active, -> { active_token.not_revoked }
  scope :with_token, ->(token) { where(token_digest: Digest::SHA256.hexdigest(token)) }

  delegate :name, to: :appropriate_body_period, allow_nil: true, prefix: :appropriate_body

  def active? = token_active? && not_revoked?

  def existing_active_authorization
    return if client.blank?

    client
      .authorizations
      .active
      .where(appropriate_body_period:, redirect_uri:)
      .where.not(id:)
      .first
  end

  def error_messages_description = errors.full_messages.join(", ")

  # Add other user types as needed
  def user_name = appropriate_body_name

private

  def only_one_active_authorization
    if existing_active_authorization.present?
      errors.add(:client_id, "Only one active authorization permitted for the same client, appropriate body and redirect URI")
    end
  end
end
