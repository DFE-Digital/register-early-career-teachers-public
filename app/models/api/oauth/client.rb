class API::OAuth::Client < ApplicationRecord
  GRANT_TYPES = %w[authorization_code].freeze
  BLACKLISTED_HOSTS = %w[localhost ngrok.io ngrok.app ngrok.dev ngrok-free.app].freeze

  has_secure_token :client_id, on: :initialize

  has_many :authorizations, dependent: :destroy

  # we need to temporarily see the secret to make it available to the client.
  attr_reader :client_secret

  after_initialize :assign_client_secret, if: -> { new_record? && !client_secret_digest? }

  normalizes :name, with: -> { it.squish }
  normalizes :redirect_uris, with: -> { it.compact_blank.map(&:strip).uniq }
  normalizes :grant_types, with: -> { it.compact_blank.uniq }

  validates :name, presence: true, uniqueness: true
  validates :client_id, presence: true, uniqueness: true
  validates :client_secret_digest, presence: true, length: { is: 64 }
  validates :redirect_uris, presence: true
  validates :grant_types, presence: true, inclusion: { in: GRANT_TYPES, allow_blank: true }
  validate :redirect_uris_are_well_formed, if: :redirect_uris
  validate :redirect_uris_are_not_blacklisted, if: -> { Rails.env.production? && !any_malformed_urls? }

  def rotate_client_secret = assign_client_secret

private

  def assign_client_secret
    @client_secret = SecureRandom.base58(32)
    self.client_secret_digest = Digest::SHA256.hexdigest(@client_secret)
  end

  def redirect_uris_are_well_formed
    errors.add(:redirect_uris, :invalid) if any_malformed_urls?
  end

  def redirect_uris_are_not_blacklisted
    errors.add(:redirect_uris, "must use HTTPS and a public host") if any_blacklisted_urls?
  end

  def any_malformed_urls? = redirect_uris&.any? { malformed?(it) }
  def any_blacklisted_urls? = redirect_uris&.any? { blacklisted?(it) }

  def malformed?(redirect_uri)
    uri = URI.parse(redirect_uri)
    !uri.is_a?(URI::HTTP) || uri.host.blank? || !uri.fragment.nil?
  rescue URI::InvalidURIError
    true
  end

  def blacklisted?(redirect_uri)
    uri = URI.parse(redirect_uri)
    host = uri.host.downcase
    !uri.is_a?(URI::HTTPS) || BLACKLISTED_HOSTS.any? { host == it || host.end_with?(".#{it}") }
  end
end
