RSpec.describe API::OAuth::AccessTokenRequest, type: :model do
  subject(:instance) do
    described_class.new(
      authorization:,
      grant_type:,
      code_verifier:,
      redirect_uri:
    )
  end

  let(:client) { FactoryBot.create(:api_oauth_client, client_secret_digest:) }
  let(:client_secret) { "client-secret" }
  let(:client_secret_digest) { Digest::SHA256.hexdigest(client_secret) }

  let!(:authorization) { FactoryBot.create(:api_oauth_authorization, client:, code_challenge:) }
  let(:challenge) { "code-challenge" }
  let(:code_challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(challenge), padding: false) }

  let(:grant_type) { client.grant_types.first }
  let(:code_verifier) { challenge }
  let(:redirect_uri) { client.redirect_uris.first }
  let(:code_expires_at) { 1.day.from_now }
  let(:code_exchanged_at) { nil }
  let(:appropriate_body_period) { authorization.appropriate_body_period }

  before { authorization.update!(code_expires_at:, code_exchanged_at:) }

  describe "validations" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:authorization).with_message("invalid_grant") }
    it { is_expected.to validate_presence_of(:grant_type).with_message("invalid_request") }
    it { is_expected.to validate_presence_of(:code_verifier).with_message("invalid_grant") }
    it { is_expected.to validate_presence_of(:redirect_uri).with_message("invalid_grant") }

    context "when the grant_type is not supported" do
      let(:grant_type) { "froot" }

      it { is_expected.to have_one_error_only }
      it { is_expected.to have_error(:grant_type, "unsupported_grant_type") }
    end

    context "when the code has expired" do
      let(:code_expires_at) { 1.hour.ago }

      it { is_expected.to have_one_error_only }
      it { is_expected.to have_error(:code, "invalid_grant") }
    end

    context "when the code has already been exchanged" do
      let(:code_exchanged_at) { 1.hour.ago }

      it { is_expected.to have_one_error_only }
      it { is_expected.to have_error(:code, "invalid_grant") }
    end

    context "when the code_verifier cannot be verified" do
      let(:code_verifier) { "grapefruit" }

      it { is_expected.to have_one_error_only }
      it { is_expected.to have_error(:code_verifier, "invalid_grant") }
    end

    context "when the redirect_uri does not match the Authorization" do
      let(:redirect_uri) { "https://bananas.com" }

      it { is_expected.to have_one_error_only }
      it { is_expected.to have_error(:redirect_uri, "invalid_grant") }
    end
  end

  describe "#exchange_code_for_token!" do
    subject(:exchange_code_for_token!) { instance.exchange_code_for_token! }

    it { is_expected.to eq(authorization) }

    it "sets the token attributes" do
      freeze_time

      exchange_code_for_token!

      expect(authorization.reload).to have_attributes({
        token_expires_at: 1.year.from_now,
        token_digest: be_present,
        code_exchanged_at: Time.zone.now,
      })
    end

    context "when the code cannot be exchanged" do
      let(:code_expires_at) { 1.day.ago }

      it { expect { exchange_code_for_token! }.to raise_error(API::OAuth::AccessTokenRequest::RequestNotExchangeableError, "Request is not exchangeable") }
    end
  end

  describe "#access_token" do
    subject(:access_token) { instance.access_token }

    it "returns nil when the code has not been exchanged" do
      expect(access_token).to be_nil
    end

    it "returns the access token when the code has been exchanged" do
      freeze_time
      authorization = instance.exchange_code_for_token!
      expect(access_token).to eq({
        access_token: authorization.token,
        expires_in: authorization.seconds_to_token_expiration,
        token_type: "Bearer",
      })
    end
  end

  describe "#error_message" do
    subject(:error_message) { instance.error_message }

    it "returns nil when there are no errors" do
      expect(error_message).to be_nil
    end

    context "when there are errors" do
      let(:grant_type) { "froot" }
      let(:code_expires_at) { 1.hour.ago }

      it "returns the first error message when there are errors" do
        expect(instance).to be_invalid
        expect(error_message).to eq({ error: instance.errors.first.message })
      end
    end
  end
end
