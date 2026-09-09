describe API::OAuth::Authorizations::Create do
  include ActiveJob::TestHelper

  subject(:service) { described_class.new(authorization_request:, author:) }

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:client) { FactoryBot.create(:api_oauth_client) }
  let(:author) do
    FactoryBot.build(:appropriate_body_user, dfe_sign_in_organisation_id: appropriate_body_period.dfe_sign_in_organisation_id)
  end

  let(:authorization_request) do
    API::OAuth::AuthorizationRequest.new(
      logged_in_appropriate_body_period_id: appropriate_body_period.id,
      appropriate_body_period_id: appropriate_body_period.id,
      client_id: client.client_id,
      redirect_uri:,
      response_type: "code",
      code_challenge: "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
      code_challenge_method: "S256",
      state: "xyz"
    )
  end

  context "when valid" do
    let(:redirect_uri) { client.redirect_uris.first }

    it "creates an authorization for the request and records an event" do
      authorization = service.call
      expect { perform_enqueued_jobs }.to change(Event, :count).by(1)
      event = Event.with_event_type(:oauth_authorization_created).sole
      expect(authorization).to be_a(API::OAuth::Authorization).and(be_persisted)
      expect(authorization.client).to eq(client)
      expect(authorization.appropriate_body_period).to eq(appropriate_body_period)
      expect(authorization.redirect_uri).to eq(client.redirect_uris.first)
      expect(authorization.code_challenge).to eq(authorization_request.code_challenge)
      expect(authorization).to be_s256
      expect(authorization.code).to be_present
      expect(event.appropriate_body_period).to eq(appropriate_body_period)
      expect(event.author_email).to eq(author.email)
      expect(event.metadata).to eq("client_name" => client.name, "client_id" => client.client_id)
    end
  end

  context "when invalid" do
    let(:redirect_uri) { "https://elsewhere.example.com/oauth/callback" }

    it "returns the unsaved authorization and records no event" do
      authorization = service.call
      expect { perform_enqueued_jobs }.not_to change(Event, :count)
      expect(authorization).not_to be_persisted
      expect(authorization.errors[:redirect_uri]).to include("is not included in the list")
    end
  end
end
