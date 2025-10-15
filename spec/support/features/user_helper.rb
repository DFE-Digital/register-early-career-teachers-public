module UserHelper
  # rubocop:disable RSpec/AnyInstance
  def sign_in_as_unrecognised_user
    Rails.logger.debug("Signing in with dfe sign in as an unrecognised user")
    allow_any_instance_of(PagesController).to receive(:session).and_return({ invalid_user_organisation_name: 'Invalid Organisation' })
    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_codes: %w[UnknownRole]))
    mock_dfe_sign_in_provider!(email: Faker::Internet.email,
                               uid: Faker::Internet.uuid,
                               first_name: Faker::Name.first_name,
                               last_name: Faker::Name.last_name,
                               organisation_id: Faker::Internet.uuid,
                               organisation_urn: Faker::Number.unique.number(digits: 6))
    page.goto("/auth/dfe/callback")
    stop_mocking_dfe_sign_in_provider!
  end
  # rubocop:enable RSpec/AnyInstance

  def sign_in_as_multi_role_user(appropriate_body:,
                                 school:,
                                 email: Faker::Internet.email,
                                 first_name: Faker::Name.first_name,
                                 last_name: Faker::Name.last_name,
                                 uid: Faker::Internet.uuid)
    Rails.logger.debug("Signing in with dfe sign in as an SIT from an AB School")
    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_codes: %w[SchoolUser AppropriateBodyUser]))
    mock_dfe_sign_in_provider!(email:,
                               uid:,
                               first_name:,
                               last_name:,
                               organisation_id: appropriate_body.dfe_sign_in_organisation_id,
                               organisation_urn: school.urn)
    page.goto("/auth/dfe/callback")
    stop_mocking_dfe_sign_in_provider!
  end

  def sign_in_as_appropriate_body_user(appropriate_body:,
                                       email: Faker::Internet.email,
                                       first_name: Faker::Name.first_name,
                                       last_name: Faker::Name.last_name,
                                       uid: Faker::Internet.uuid)
    Rails.logger.debug("Signing in with dfe sign in as appropriate body user")
    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_codes: %w[AppropriateBodyUser]))
    mock_dfe_sign_in_provider!(email:,
                               uid:,
                               first_name:,
                               last_name:,
                               organisation_id: appropriate_body.dfe_sign_in_organisation_id)
    page.goto("/auth/dfe/callback")
    stop_mocking_dfe_sign_in_provider!
  end

  def sign_in_as_school_user(school:,
                             email: Faker::Internet.email,
                             first_name: Faker::Name.first_name,
                             last_name: Faker::Name.last_name,
                             uid: Faker::Internet.uuid)
    Rails.logger.debug("Signing in with dfe sign in as appropriate body user")
    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_codes: %w[SchoolUser]))
    mock_dfe_sign_in_provider!(email:,
                               uid:,
                               first_name:,
                               last_name:,
                               organisation_urn: school.urn)
    page.goto("/auth/dfe/callback")
    stop_mocking_dfe_sign_in_provider!
  end

  def sign_in_as_dfe_user(role:, user: FactoryBot.create(:user, role, email: Faker::Internet.email, name: Faker::Name.name))
    page.goto(otp_sign_in_path)
    page.get_by_label('Email address').type(user.email)
    page.get_by_role("button", name: 'Request code to sign in').click
    page.get_by_label('Sign in code').type(ROTP::TOTP.new(user.reload.otp_secret, issuer: "ECF2").now)
    page.get_by_role("button", name: 'Sign in').click
  end

  def sign_out
    page.goto(otp_sign_out_path)
  end
end

RSpec.configure do |config|
  config.include UserHelper, type: :feature
end
