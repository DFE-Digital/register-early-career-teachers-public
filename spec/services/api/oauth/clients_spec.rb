RSpec.describe API::OAuth::Clients do
  subject(:clients) { described_class.new(author:) }

  let(:user) { FactoryBot.create(:user) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  describe "#create!" do
    let(:params) { { name: "Alpha Induction Platform", redirect_uris: %w[https://alpha.example.com/callback] } }

    it "creates the client and records its name and redirect URIs" do
      client = clients.create!(params:)

      expect(client).to be_persisted
      expect(client).to have_attributes(grant_types: API::OAuth::Client::GRANT_TYPES)
      expect(Event.sole).to have_attributes(event_type: "api_client_created", oauth_client: client, author_email: user.email)
      expect(Event.sole.metadata).to eq(
        "name" => [nil, "Alpha Induction Platform"],
        "redirect_uris" => [[], %w[https://alpha.example.com/callback]]
      )
    end

    it "raises and records nothing when the client is invalid" do
      expect { clients.create!(params: params.merge(name: "")) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(API::OAuth::Client.count).to eq(0)
      expect(Event.count).to eq(0)
    end
  end

  describe "#update!" do
    let(:client) { FactoryBot.create(:api_oauth_client, name: "Alpha Induction Platform") }

    it "updates the client and records the changes without the secret digest" do
      client_secret_digest = Digest::SHA256.hexdigest("new secret")

      clients.update!(client:, params: { name: "Beta Induction Platform", client_secret_digest: })

      expect(client.reload).to have_attributes(name: "Beta Induction Platform", client_secret_digest:)
      expect(Event.sole).to have_attributes(
        event_type: "api_client_updated",
        oauth_client: client,
        author_email: user.email,
        metadata: { "name" => ["Alpha Induction Platform", "Beta Induction Platform"] }
      )
    end

    it "records nothing when nothing changed" do
      clients.update!(client:, params: { name: "Alpha Induction Platform" })

      expect(Event.count).to eq(0)
    end

    it "raises and records nothing when the update is invalid" do
      expect { clients.update!(client:, params: { name: "" }) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(client.reload.name).to eq("Alpha Induction Platform")
      expect(Event.count).to eq(0)
    end
  end

  describe "#rotate_secret!" do
    let(:client) { FactoryBot.create(:api_oauth_client, name: "Alpha Induction Platform") }

    it "replaces the secret and records an event without the secret digest" do
      previous_secret = client.client_secret

      clients.rotate_secret!(client:)

      expect(client.reload.secret_matches?(secret: previous_secret)).to be(false)
      expect(Event.sole).to have_attributes(event_type: "api_client_secret_rotated", oauth_client: client, author_email: user.email, metadata: nil)
    end
  end
end
