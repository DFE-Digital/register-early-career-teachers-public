class API::OAuth::Authorization < ApplicationRecord
  CODE_EXPIRY = 10.minutes
  TOKEN_EXPIRY = 1.year

  enum :code_challenge_method, { s256: "S256" }, validate: true

  belongs_to :client
  belongs_to :appropriate_body_period

  validates :client, :appropriate_body_period, presence: true
  validates :redirect_uri, presence: true, inclusion: { in: -> { it.client.redirect_uris }, allow_blank: true, if: :client, on: :create }
  validates :code_digest, presence: true, uniqueness: true
  validates :code_challenge, presence: true
  validates :code_expires_at, presence: true
  validates :token_digest, uniqueness: true, allow_nil: true
  validates :token_expires_at, presence: true, if: :token_digest

  def assign_code
    SecureRandom.base58(32).tap do |code|
      self.code_digest = Digest::SHA256.hexdigest(code)
      self.code_expires_at = CODE_EXPIRY.from_now
    end
  end

  def assign_token
    SecureRandom.base58(32).tap do |token|
      self.token_digest = Digest::SHA256.hexdigest(token)
      self.token_expires_at = TOKEN_EXPIRY.from_now
    end
  end

  def code_expired? = code_expires_at&.past?
  def token_expired? = token_expires_at&.past?
end
