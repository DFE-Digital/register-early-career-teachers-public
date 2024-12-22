module AuthHelper
  def sign_in_as(user_type, method: :persona, appropriate_body: nil, school: nil, user: nil)
    Rails.logger.info("logging in as #{user_type}")

    case method
    when :dfe_sign_in then sign_in_with_dfe_sign_in(user_type)
    when :otp then sign_in_with_otp(user)
    when :persona then sign_in_with_persona(user_type, appropriate_body:, school:, user:)
    end
  end

private

  def sign_in_with_dfe_sign_in(user_type)
    case user_type
    when :appropriate_body_user
      sign_in_with_appropriate_body_user(appropriate_body:)
    when :school_user
      sign_in_with_school_user(school:)
    end
  end

  def sign_in_with_otp(user)
    post(otp_sign_in_path, params: { sessions_otp_sign_in_form: { email: user.email } })
    post(otp_sign_in_verify_path,
         params: {
           sessions_otp_sign_in_form: {
             code: Sessions::OneTimePassword.new(user:).generate }
         })
  end

  def sign_in_with_persona(user_type, appropriate_body:, user:, school:)
    case user_type
    when :appropriate_body_user
      sign_in_with_appropriate_body_persona(appropriate_body:)
    when :dfe_user
      sign_in_with_dfe_persona(user:)
    when :school_user
      sign_in_with_school_persona(school:)
    end
  end

  def sign_in_with_appropriate_body_user(appropriate_body:,
                                         email: Faker::Internet.email,
                                         first_name: Faker::Name.first_name,
                                         last_name: Faker::Name.last_name,
                                         uid: Faker::Internet.uuid)
    Rails.logger.debug("Signing in with dfe sign in as appropriate body user")
    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new)
    mock_dfe_sign_in_provider!(email:,
                               uid:,
                               first_name:,
                               last_name:,
                               organisation_id: appropriate_body.dfe_sign_in_organisation_id)
    post("/auth/dfe/callback")
    stop_mocking_dfe_sign_in_provider!
  end

  def sign_in_with_school_user(school:,
                               email: Faker::Internet.email,
                               first_name: Faker::Name.first_name,
                               last_name: Faker::Name.last_name,
                               uid: Faker::Internet.uuid)
    Rails.logger.debug("Signing in with dfe sign in as appropriate body user")
    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new)
    mock_dfe_sign_in_provider!(email:,
                               uid:,
                               first_name:,
                               last_name:,
                               organisation_urn: school.urn)
    post("/auth/dfe/callback")
    stop_mocking_dfe_sign_in_provider!
  end

  def sign_in_with_appropriate_body_persona(appropriate_body:, email: Faker::Internet.email, name: Faker::Name.name)
    Rails.logger.debug("Signing in with persona as appropriate body user")
    post("/auth/persona/callback", params: { email:, name:, appropriate_body_id: appropriate_body.id })
  end

  def sign_in_with_dfe_persona(user:)
    Rails.logger.debug("Signing in with persona as dfe user")
    post('/auth/persona/callback', params: { email: user.email, name: user.name, dfe_staff: true })
  end

  def sign_in_with_school_persona(school:, name: Faker::Name.name, email: Faker::Internet.email)
    Rails.logger.debug("Signing in with persona as school user")
    post("/auth/persona/callback", params: { email:, name:, school_urn: school.urn })
  end
end

RSpec.configure { |config| config.include(AuthHelper, type: :request) }
