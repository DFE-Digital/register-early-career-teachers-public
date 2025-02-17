# Setup omniauth providers to authenticate personas, appropriate body and school users

OmniAuth.config.add_camelization('openid_connect_with_id_token_hint', 'OpenIDConnectWithIdTokenHint')

Rails.application.config.middleware.use(OmniAuth::Builder) do
  # setup 'persona' oauth provider
  if Rails.application.config.enable_personas
    provider(
      :developer,
      name: 'persona',
      fields: %i[name email school_urn appropriate_body_id dfe_staff],
      uid_field: :email
    )
  end

  # setup 'dfe_sign_in' oauth provider
  if Rails.application.config.dfe_sign_in_enabled
    issuer_uri = URI(Rails.application.config.dfe_sign_in_issuer)

    provider(
      :openid_connect_with_id_token_hint,
      callback_path: '/auth/dfe/callback',
      client_options: {
        host: issuer_uri.host,
        identifier: Rails.application.config.dfe_sign_in_client_id,
        port: issuer_uri.port,
        redirect_uri: Rails.application.config.dfe_sign_in_redirect_uri,
        scheme: issuer_uri.scheme,
        secret: Rails.application.config.dfe_sign_in_secret,
      },
      discovery: true,
      issuer: "#{issuer_uri}:#{issuer_uri.port}",
      name: 'dfe_sign_in',
      path_prefix: '/auth',
      response_type: :code,
      scope: %w[openid profile email organisation],
      post_logout_redirect_uri: Rails.application.config.dfe_sign_in_sign_out_redirect_uri
    )
  end

  OmniAuth.config.logger = Rails.logger
end
