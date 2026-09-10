RSpec.describe API::OAuth::AuthorizationToken, type: :model do
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

  describe "#create" do
    subject(:result) { instance.create }

    # before do
    #   allow(RecordEventJob).to receive(:perform_later).and_return(true)
    # end

    it "marks the authorization as exchanged" do
      result
      expect(authorization.reload.code_exchanged_at).to be_within(1.second).of Time.zone.now
    end

    it "generates an event" do
      freeze_time do
        expect {
          result
        }.to have_enqueued_job(RecordEventJob).with(
          author_name: client.name,
          author_type: "api_oauth_client",
          event_type: :api_oauth_authorization_code_exchanged,
          happened_at: Time.zone.now,
          appropriate_body_period: authorization.appropriate_body_period,
          heading: "Authorization code exchanged by client '#{client.name}' for '#{authorization.appropriate_body_period.name}'"
        )
      end
    end

    it "the queued job adds an event record when performed" do
      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true

      expect {
        result
      }.to change(Event, :count).by(1)

      expect(Event.first.event_type).to eq "api_oauth_authorization_code_exchanged"
    end

    it "creates and returns the token information" do
      token, token_expires_at = result
      expect(Digest::SHA256.hexdigest(token)).to eq authorization.reload.token_digest
      expect(token_expires_at).to be_within(1.second).of(365.days.from_now)
    end
  end
end
