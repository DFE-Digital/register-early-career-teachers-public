RSpec.describe "API OAuth Token Handshake", type: :request do
  describe "#create" do
    let(:path) { api_oauth_authorization_handshake_path }
    let(:params) do
      {
        grant_type:,
        code: raw_code,
        code_verifier: raw_code_verifier,
        redirect_uri:
      }
    end

    let(:client) { FactoryBot.create(:api_oauth_client) }
    let(:authorization) { FactoryBot.create(:api_oauth_authorization, client:, code_digest:, code_verifier:) }
    let(:grant_type) { client.grant_types.first }
    let(:raw_code) { "secret code" }
    let(:code_digest) { Base64.urlsafe_encode64(Digest::SHA256.digest(raw_code), padding: false) }
    let(:raw_code_verifier) { "super-secret-code" }
    let(:code_verifier) { Base64.urlsafe_encode64(Digest::SHA256.digest(raw_code_verifier), padding: false) }
    let(:redirect_uri) { client.redirect_uris.first }

  end
end
