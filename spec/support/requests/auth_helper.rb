module AuthHelper
  def sign_in_as(user_type, method: :persona, appropriate_body: nil, school_urn:)
    Rails.logger.info("logging in as #{user_type}")

    case method
    when :otp then sign_in_with_otp(user_type)
    when :persona then sign_in_with_persona(user_type, appropriate_body:, school_urn:)
    end
  end

private

  def sign_in_with_otp(user_type)
    FactoryBot.create(:user, user_type).tap do |user|
      post(otp_sign_in_path, params: { sessions_otp_sign_in_form: { email: user.email } })
      post(
        otp_sign_in_verify_path,
        params: {
          sessions_otp_sign_in_form: { code: Sessions::OneTimePassword.new(user:).generate },
        }
      )
    end
  end

  def sign_in_with_persona(user_type, appropriate_body:, school_urn:)
    case user_type
    when :appropriate_body_user
      sign_in_with_appropriate_body_persona(appropriate_body:)
    when :school_user
      sign_in_with_school_persona(school_urn:)
    end
  end

  def sign_in_with_appropriate_body_persona(appropriate_body:, name: Faker::Name.name, email: Faker::Internet.email)
    Rails.logger.debug("Signing in with persona as appropriate body user")
    post("/auth/developer/callback", params: { email:, name:, appropriate_body_id: appropriate_body.id })
  end

  def sign_in_with_school_persona(school_urn:, name: Faker::Name.name, email: Faker::Internet.email)
    Rails.logger.debug("Signing in with persona as school user")
    post("/auth/developer/callback", params: { email:, name:, school_urn: })
  end
end

RSpec.configure { |config| config.include(AuthHelper, type: :request) }
