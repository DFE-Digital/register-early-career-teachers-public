module API::OAuth::Authorization::ExchangesCodeForToken
  extend ActiveSupport::Concern

  class CodeNotExchangedError < StandardError; end

  def exchange_code_for_token!(code_verifier:)
    if code_exchangable? && code_challenge_verified?(code_verifier:)
      assign_token
      update!(code_exchanged_at: Time.zone.now)
    else
      raise CodeNotExchangedError, "Code cannot be exchanged or is not verified"
    end

    token
  end

  def code_exchangable?
    code_exchanged_at.blank? && !code_expired?
  end

  def code_challenge_verified?(code_verifier:)
    return false unless s256?

    presented_code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)

    ActiveSupport::SecurityUtils.secure_compare(code_challenge, presented_code_challenge)
  end
end
