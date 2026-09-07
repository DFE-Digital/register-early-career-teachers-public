RSpec.describe "OTP sessions", type: :request do
  let(:email) { "user@education.gov.uk" }
  let(:name) { "Test User" }
  let(:user) { FactoryBot.create(:user, email:, name:) }

  let(:sign_in_with_otp) do
    post(otp_sign_in_path, params: { sessions_otp_sign_in_form: { email: user.email } })
    post(otp_sign_in_verify_path, params: { sessions_otp_sign_in_form: { code: Sessions::OneTimePassword.new(user:).generate } })
  end

  it "allows DfE users to access the admin area" do
    sign_in_with_otp

    expect(response).to redirect_to(admin_path)
    expect(session.dig("user_session", "type")).to eq("Sessions::Users::DfEUser")
  end

  it "does not set an id_token cookie" do
    sign_in_with_otp

    expect(response.headers["Set-Cookie"].to_s).not_to include("id_token")
  end
end
