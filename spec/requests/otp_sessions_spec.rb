RSpec.describe "OTP sessions", type: :request do
  include ActionView::Helpers::SanitizeHelper

  let(:otp_school_sign_in_enabled) { true }
  let(:email) { "user@example.com" }
  let(:name) { "Test User" }
  let(:otp_school_urn) { nil }
  let(:user) { FactoryBot.create(:user, email:, name:, otp_school_urn:) }

  let(:sign_in_with_otp) do
    post(otp_sign_in_path, params: { sessions_otp_sign_in_form: { email: user.email } })
    post(otp_sign_in_verify_path, params: { sessions_otp_sign_in_form: { code: Sessions::OneTimePassword.new(user:).generate } })
  end

  before do
    allow(Rails.application.config).to receive(:enable_otp_school_sign_in).and_return(otp_school_sign_in_enabled)
  end

  context "when ENABLE_OTP_SCHOOL_SIGN_IN is true" do
    context "when the user has no urn and a non DfE email" do
      it "blocks access" do
        sign_in_with_otp

        expect(response).to have_http_status(:ok)
        expect(sanitize(response.body)).to include("This account is not enabled for one time password sign in")
        expect(session["user_session"]).to be_nil
      end
    end

    context "when the user has no urn and a DfE email" do
      let(:email) { "user@education.gov.uk" }

      it "allows admin access" do
        sign_in_with_otp

        expect(response).to redirect_to(admin_path)
        expect(session.dig("user_session", "type")).to eq("Sessions::Users::DfEUser")
      end
    end

    context "when the user has a school urn that exists in GIAS" do
      let(:email) { "user@external.com" }
      let(:otp_school_urn) { "123456" }

      before do
        FactoryBot.create(:gias_school, :open, :state_school_type, urn: otp_school_urn)
      end

      it "allows school access" do
        sign_in_with_otp

        expect(response).to redirect_to(schools_ects_home_path)
        expect(session.dig("user_session", "type")).to eq("Sessions::Users::OTPSchoolUser")
      end
    end
  end

  context "when ENABLE_OTP_SCHOOL_SIGN_IN is false" do
    let(:otp_school_sign_in_enabled) { false }

    context "when the user has no urn and a non DfE email" do
      let(:email) { "user@external.com" }

      it "blocks access" do
        sign_in_with_otp

        expect(response).to have_http_status(:ok)
        expect(sanitize(response.body)).to include("This account is not enabled for one time password sign in")
        expect(session["user_session"]).to be_nil
      end
    end

    context "when the user has a school urn that exists in GIAS and a non DfE email" do
      let(:email) { "user@external.com" }
      let(:otp_school_urn) { "123456" }

      before do
        FactoryBot.create(:gias_school, :open, :state_school_type, urn: otp_school_urn)
      end

      it "blocks access" do
        sign_in_with_otp

        expect(response).to have_http_status(:ok)
        expect(sanitize(response.body)).to include("This account is not enabled for one time password sign in")
        expect(session["user_session"]).to be_nil
      end
    end

    context "when the user has no urn and a DfE email" do
      let(:email) { "user@education.gov.uk" }

      it "allows admin access" do
        sign_in_with_otp

        expect(response).to redirect_to(admin_path)
        expect(session.dig("user_session", "type")).to eq("Sessions::Users::DfEUser")
      end
    end
  end
end
