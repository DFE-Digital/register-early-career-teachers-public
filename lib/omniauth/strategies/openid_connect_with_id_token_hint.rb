require 'omniauth_openid_connect'

module OmniAuth
  module Strategies
    class OpenIDConnectWithIdTokenHint < OmniAuth::Strategies::OpenIDConnect
      option :name, 'openid_connect_with_id_token_hint'

      def encoded_post_logout_redirect_uri
        return unless options.post_logout_redirect_uri

        URI.encode_www_form(
          post_logout_redirect_uri: options.post_logout_redirect_uri,
          id_token_hint: decrypt_token(request.cookies["id_token"])
        )
      end

    private

      def decrypt_token(encrypted_token)
        secret_key = Rails.application.secret_key_base.byteslice(0, 32)
        encryptor = ActiveSupport::MessageEncryptor.new(secret_key)
        encryptor.decrypt_and_verify(Zlib::Inflate.inflate(Base64.strict_decode64(encrypted_token)))
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        raise "Can't decrypt the id_token to be sent to DfE Sign In provider to sign the user out!"
      end
    end
  end
end
