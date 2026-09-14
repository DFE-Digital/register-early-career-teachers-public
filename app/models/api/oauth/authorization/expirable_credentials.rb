module API::OAuth::Authorization::ExpirableCredentials
  extend ActiveSupport::Concern

  class CodeNotExchangedError < StandardError; end

  CODE_EXPIRES_IN = 10.minutes
  TOKEN_EXPIRES_IN = 1.year

  included do
    attr_reader :code, :token

    before_validation :assign_code, on: :create

    validates :code_digest, presence: true, uniqueness: true
    validates :code_expires_at, presence: true
    validates :token_digest, uniqueness: true, allow_nil: true
    validates :token_expires_at, presence: true, if: :token_digest
  end

  def code_expired? = code_expires_at&.past?
  def token_expired? = token_expires_at&.past?

  def seconds_to_token_expiration
    return if token_expires_at.blank?

    seconds = (token_expires_at - Time.zone.now).round
    seconds.negative? ? 0 : seconds
  end

  def exchange_code_for_token!(code_verifier:)
    raise(CodeNotExchangedError, "Code cannot be exchanged") unless code_exchangable?
    raise(CodeNotExchangedError, "Code verifier is invalid") unless code_challenge_verified?(code_verifier:)

    assign_token.tap { update!(code_exchanged_at: Time.zone.now) }
  end

  def code_exchangable?
    code_exchanged_at.blank? && !code_expired?
  end

  def code_challenge_verified?(code_verifier:)
    return false unless s256?

    presented_code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)

    ActiveSupport::SecurityUtils.secure_compare(code_challenge, presented_code_challenge)
  end

private

  def assign_token
    @token, self.token_digest, self.token_expires_at = new_expirable_secret_with_digest(TOKEN_EXPIRES_IN)
  end

  def assign_code
    @code, self.code_digest, self.code_expires_at = new_expirable_secret_with_digest(CODE_EXPIRES_IN)
  end

  def new_expirable_secret_with_digest(expires_in)
    secret = SecureRandom.base58(32)

    [secret, Digest::SHA256.hexdigest(secret), expires_in.from_now]
  end
end
