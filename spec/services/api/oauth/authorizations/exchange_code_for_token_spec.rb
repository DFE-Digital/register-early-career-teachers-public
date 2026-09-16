describe API::OAuth::Authorizations::ExchangeCodeForToken do
  include ActiveJob::TestHelper

  subject(:service) { described_class.new(access_token_request:) }

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:client) { FactoryBot.create(:api_oauth_client) }

  let(:code_verifier) { "code-verifier" }
  let(:author) { Events::OAuthClientAuthor.new(client:) }

  let(:access_token_request) do
    API::OAuth::AccessTokenRequest.new(
      client:,
      redirect_uri: client.redirect_uris.sample,
      grant_type: client.grant_types.first,
      code: authorization.code,
      code_verifier:
    )
  end

  let(:authorization) { FactoryBot.create(:api_oauth_authorization, appropriate_body_period:, client:, code_verifier:) }

  context "when valid" do
    it "returns an authorization with a token and emits an event" do
      freeze_time

      authorization = service.call
      expect { perform_enqueued_jobs }.to change(Event, :count).by(1)

      event = Event.with_event_type(:api_oauth_authorization_code_exchanged).sole
      expect(event.appropriate_body_period).to eq(appropriate_body_period)
      expect(event.author_type).to eq("oauth_client")
      expect(event.author_name).to eq(client.name)

      expect(authorization.token_expires_at).to eq(1.year.from_now)
      expect(authorization.token_digest).to be_present
      expect(authorization.code_exchanged_at).to eq(Time.zone.now)
    end
  end

  context "when invalid" do
    before { authorization.update!(code_challenge: "something-else") }

    it "raises an error without setting token or recording an event" do
      expect { service.call }.to raise_error(API::OAuth::Authorization::ExpirableCredentials::CodeNotExchangedError)

      expect { perform_enqueued_jobs }.not_to change(Event, :count)

      authorization.reload
      expect(authorization.token_expires_at).to be_nil
      expect(authorization.token_digest).to be_nil
      expect(authorization.code_exchanged_at).to be_nil
    end
  end
end
