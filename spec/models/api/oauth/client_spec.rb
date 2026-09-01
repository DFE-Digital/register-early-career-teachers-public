describe API::OAuth::Client do
  describe "associations" do
    it { is_expected.to have_many(:authorizations).dependent(:destroy) }
  end

  describe "validations" do
    subject(:client) { FactoryBot.build(:api_oauth_client, name: "ECT Manager", redirect_uris:, grant_types:) }

    let(:redirect_uris) { %w[https://ect_manager.com/oauth/callback] }
    let(:grant_types) { %w[authorization_code] }

    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_uniqueness_of(:client_id) }
    it { is_expected.to validate_presence_of(:client_secret_digest) }
    it { is_expected.to validate_length_of(:client_secret_digest).is_equal_to(64) }
    it { is_expected.to validate_presence_of(:redirect_uris) }
    it { is_expected.to validate_presence_of(:grant_types) }

    describe "redirect URIs" do
      let(:public_https_uris) do
        %w[
          https://www.vendor.com/oauth/callback
          https://www.vendor.com:8443/oauth/callback?state=abc
          https://8.8.8.8/callback
        ]
      end

      let(:malformed_uris) do
        [
          "not a uri",
          "/oauth/callback",
          "vendor.com/oauth/callback",
          "ftp://vendor.example.com/oauth/callback"
        ]
      end

      let(:http_or_local_uris) do
        %w[
          http://www.vendor.com/oauth/callback
        ]
      end

      let(:blacklisted_uris) do
        %w[
          https://localhost:3000/oauth/callback
          https://app.localhost/oauth/callback
          https://abc123.ngrok-free.app/oauth/callback
        ]
      end

      it "rejects malformed uris but not http or local urls" do
        expect_redirect_uris_valid(public_https_uris + http_or_local_uris)
        expect_redirect_uris_invalid(malformed_uris, "is invalid")
      end

      context "in production" do
        before { allow(Rails.env).to receive(:production?).and_return(true) }

        it "if rejects malformed, http and local urls" do
          expect_redirect_uris_valid(public_https_uris)
          expect_redirect_uris_invalid(http_or_local_uris, "must use HTTPS and a public host")
          expect_redirect_uris_invalid(blacklisted_uris, "must use HTTPS and a public host")
        end
      end
    end

    context "when grant_type is unsupported" do
      let(:grant_types) { %w[invalid] }

      it "is invalid" do
        expect(client).not_to be_valid
        expect(client.errors[:grant_types]).to include("is not included in the list")
      end
    end
  end

  context "when initialized" do
    subject(:client) { described_class.new }

    it "generates a client id and a client secret, storing a digest of the secret" do
      expect(client.client_id).to be_present
      expect(client.client_secret.length).to be_present
      expect(client.client_secret_digest).to eq(Digest::SHA256.hexdigest(client.client_secret))
    end
  end

  context "when loaded from the database" do
    subject(:client) { described_class.find(FactoryBot.create(:api_oauth_client).id) }

    it "does not have the client secret" do
      expect(client.client_secret).to be_nil
      expect(client.client_secret_digest).to be_present
    end
  end

  describe "#rotate_client_secret" do
    subject(:client) { described_class.new }

    it "replaces the current client secret and its digest" do
      expect { client.rotate_client_secret }.to change(client, :client_secret).and change(client, :client_secret_digest)
      expect(client.client_secret_digest).to eq(Digest::SHA256.hexdigest(client.client_secret))
    end
  end

  context "when there is unexpected whitespace" do
    subject(:client) do
      described_class.new(
        name: "  ECT    Manager ",
        redirect_uris: [" https://ect_maanger.com/oauth/callback ", "   ", nil],
        grant_types: %w[authorization_code authorization_code]
      )
    end

    it "normalizes" do
      expect(client.name).to eq("ECT Manager")
      expect(client.redirect_uris).to eq(%w[https://ect_maanger.com/oauth/callback])
      expect(client.grant_types).to eq(%w[authorization_code])
    end
  end

  def expect_redirect_uris_valid(uris)
    uris.each do |uri|
      client.redirect_uris = [uri]
      expect(client).to be_valid, "expected #{uri.inspect} to be valid"
    end
  end

  def expect_redirect_uris_invalid(uris, message)
    uris.each do |uri|
      client.redirect_uris = [uri]
      expect(client).not_to be_valid, "expected #{uri.inspect} to be invalid"
      expect(client.errors[:redirect_uris]).to eq([message])
    end
  end
end
