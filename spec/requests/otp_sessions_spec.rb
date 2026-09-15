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

    before do
      user.destroy!
    end

    it "does not send an OTP code" do
      expect {
        post(otp_sign_in_path, params: { sessions_otp_sign_in_form: { email: removed_email } })
      }.not_to have_enqueued_mail(OTPMailer, :otp_code_email)
    end

    it "does not allow the user to sign in" do
      post(otp_sign_in_path, params: { sessions_otp_sign_in_form: { email: removed_email } })
      post(otp_sign_in_verify_path, params: { sessions_otp_sign_in_form: { code: "123456" } })

      aggregate_failures do
        expect(response).not_to redirect_to(admin_path)
        expect(session["user_session"]).to be_blank
      end
    end
  end
end
