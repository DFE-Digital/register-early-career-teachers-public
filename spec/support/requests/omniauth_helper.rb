module OmniAuthHelper
  def mock_dfe_sign_in_provider!(**args)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:dfe_sign_in] = OmniAuth::AuthHash.new(
      provider: 'dfe_sign_in',
      callback_path: '/auth/dfe/callback',
      uid: args[:uid],
      info: {
        email: args[:email],
        first_name: args[:first_name],
        last_name: args[:last_name],
      },
      extra: {
        raw_info: {
          organisation: {
            id: args[:organisation_id],
            urn: args[:organisation_urn],
          }
        }
      },
      credentials: {
        id_token: 'mock_id_token',
        token: 'mock_token',
        refresh_token: 'mock_refresh_token',
        expires_at: Time.current + 1.week
      }
    )
  end

  def stop_mocking_dfe_sign_in_provider!
    OmniAuth.config.mock_auth[:dfe_sign_in] = nil
    OmniAuth.config.test_mode = false
  end
end

RSpec.configure do |config|
  config.include(OmniAuthHelper, type: :request)
  config.include(OmniAuthHelper, type: :feature)
end
