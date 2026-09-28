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

  context "when the user has been removed" do
    let(:removed_email) { user.email }
    let(:manager) { FactoryBot.create(:user, :user_manager) }

    before do
      sign_in_as(:dfe_user, user: manager)

      delete admin_user_path(user), params: {
        admin_users_remove_user_form: { confirmed: "1" }
      }
    end

    it "removes the user" do
      expect(User.exists?(user.id)).to be(false)
    end

    it "does not send an OTP code" do
      expect {
        post otp_sign_in_path, params: {
          sessions_otp_sign_in_form: { email: removed_email }
        }
      }.not_to have_enqueued_mail(OTPMailer, :otp_code_email)
    end

    it "does not allow the removed user to sign in" do
      post otp_sign_in_path, params: {
        sessions_otp_sign_in_form: { email: removed_email }
      }

      post otp_sign_in_verify_path, params: {
        sessions_otp_sign_in_form: { code: "123456" }
      }

      expect(response).not_to redirect_to(admin_path)
    end
  end
end
