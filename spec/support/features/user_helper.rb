module UserHelper
  # rubocop:disable RSpec/AnyInstance
  def sign_in_as_unrecognised_user(
    organisation_id: Faker::Internet.uuid,
    organisation_urn: Faker::Number.unique.number(digits: 6)
  )
    Rails.logger.debug("Signing in with DfE Sign-In as an unrecognised user")

    if organisation_id.present? || organisation_urn.present?
      allow_any_instance_of(PagesController).to receive(:session).and_return({ invalid_user_organisation_name: "Invalid Organisation" })
    end

    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_codes: %w[UnknownRole]))
    mock_dfe_sign_in_provider!(email: Faker::Internet.email,
                               uid: Faker::Internet.uuid,
                               first_name: Faker::Name.first_name,
                               last_name: Faker::Name.last_name,
                               organisation_id:,
                               organisation_urn:,
                               organisation_name: (Faker::Company.name if organisation_id))
    page.goto("/auth/dfe/callback")
    stop_mocking_dfe_sign_in_provider!
  end
  # rubocop:enable RSpec/AnyInstance

  # TODO: refactor sign_in_as_* methods to reduce duplication
  def sign_in_as_school_induction_tutor(appropriate_body:,
                                        school:,
                                        email: Faker::Internet.email,
                                        first_name: Faker::Name.first_name,
                                        last_name: Faker::Name.last_name,
                                        uid: Faker::Internet.uuid)
    Rails.logger.debug("Signing in with DfE Sign-In as an SIT from a TSH Lead School")
    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_codes: %w[SchoolUser AppropriateBodyUser]))
    mock_dfe_sign_in_provider!(email:,
                               uid:,
                               first_name:,
                               last_name:,
                               organisation_id: appropriate_body.dfe_sign_in_organisation_id,
                               organisation_name: school.gias_school.name,
                               organisation_urn: school.urn)
    page.goto("/auth/dfe/callback")
    stop_mocking_dfe_sign_in_provider!
  end

  def sign_in_as_teaching_school_hub(appropriate_body:,
                                     school:,
                                     role_codes: %w[AppropriateBodyUser],
                                     email: Faker::Internet.email,
                                     first_name: Faker::Name.first_name,
                                     last_name: Faker::Name.last_name,
                                     uid: Faker::Internet.uuid)
    Rails.logger.debug("Signing in with DfE Sign-In as a TSH Lead School")
    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_codes:))
    mock_dfe_sign_in_provider!(email:,
                               uid:,
                               first_name:,
                               last_name:,
                               organisation_id: appropriate_body.dfe_sign_in_organisation_id,
                               organisation_name: school.gias_school.name,
                               organisation_urn: school.urn)
    page.goto("/auth/dfe/callback")
    stop_mocking_dfe_sign_in_provider!
  end

  # NOTE: TSH user auth hash would contain a URN
  def sign_in_as_appropriate_body_user(appropriate_body:,
                                       email: Faker::Internet.email,
                                       first_name: Faker::Name.first_name,
                                       last_name: Faker::Name.last_name,
                                       uid: Faker::Internet.uuid)
    Rails.logger.debug("Signing in with DfE Sign-In as a National Appropriate Body")
    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_codes: %w[AppropriateBodyUser]))
    mock_dfe_sign_in_provider!(email:,
                               uid:,
                               first_name:,
                               last_name:,
                               organisation_id: appropriate_body.dfe_sign_in_organisation_id,
                               organisation_name: appropriate_body.name)
    page.goto("/auth/dfe/callback")
    stop_mocking_dfe_sign_in_provider!
  end

  def sign_in_as_school_user(school:,
                             email: Faker::Internet.email,
                             first_name: Faker::Name.first_name,
                             last_name: Faker::Name.last_name,
                             uid: Faker::Internet.uuid)
    Rails.logger.debug("Signing in with DfE Sign-In as appropriate body user")
    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_codes: %w[SchoolUser]))
    mock_dfe_sign_in_provider!(email:,
                               uid:,
                               first_name:,
                               last_name:,
                               organisation_urn: school.urn,
                               organisation_name: school.gias_school.name)
    page.goto("/auth/dfe/callback")
    stop_mocking_dfe_sign_in_provider!
  end

  def sign_in_as_dfe_user(role:, user: FactoryBot.create(:user, role, email: Faker::Internet.email, name: Faker::Name.name))
    page.goto(otp_sign_in_path)
    page.get_by_label("Email address").type(user.email)
    page.get_by_role("button", name: "Request code to sign in").click
    page.get_by_label("Sign in code").type(ROTP::TOTP.new(user.reload.otp_secret, issuer: "ECF2").now)
    page.get_by_role("button", name: "Sign in").click
  end

  def sign_out
    page.goto(otp_sign_out_path)
  end
end

RSpec.configure do |config|
  config.include UserHelper, type: :feature
end
