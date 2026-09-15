RSpec.describe API::OAuth::AuthorizationTokenRequest, type: :model do
  subject(:instance) do
    described_class.new(
      client:,
      grant_type:,
      code:,
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
  let(:code) { "secret code" }
  let(:code_verifier) { challenge }
  let(:redirect_uri) { client.redirect_uris.first }
  let(:code_digest) { Digest::SHA256.hexdigest(code) }
  let(:code_expires_at) { 1.day.from_now }
  let(:code_exchanged_at) { nil }
  let(:appropriate_body_period) { authorization.appropriate_body_period }

  before do
    authorization.update!(code_digest:, code_expires_at:, code_exchanged_at:)
  end

  describe "validations" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:client).with_message("invalid_client") }
    it { is_expected.to validate_presence_of(:grant_type).with_message("invalid_request") }
    it { is_expected.to validate_presence_of(:code).with_message("invalid_grant") }
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

  describe "#authorization" do
    subject { instance.authorization }

    it { is_expected.to eq(authorization) }

    context "when the authorization does not exist" do
      let(:code_digest) { Digest::SHA256.hexdigest("different code") }

      it { is_expected.to be_nil }
    end
  end
end
