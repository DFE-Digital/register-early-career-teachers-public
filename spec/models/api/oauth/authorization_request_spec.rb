describe API::OAuth::AuthorizationRequest do
  subject(:authorization_request) do
    described_class.new(
      logged_in_appropriate_body_period_id: appropriate_body_period.id,
      appropriate_body_period_id: appropriate_body_period.id,
      client_id: client.client_id,
      redirect_uri: client.redirect_uris.first,
      response_type: "code",
      code_challenge: "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
      code_challenge_method: "S256",
      state: "xyz"
    )
  end

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:client) { FactoryBot.create(:api_oauth_client) }

  describe "validations" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:response_type) }
    it { is_expected.to validate_inclusion_of(:response_type).in_array(%w[code]) }
    it { is_expected.to validate_presence_of(:code_challenge) }
    it { is_expected.to validate_inclusion_of(:code_challenge_method).in_array(%w[S256]) }
    it { is_expected.to validate_presence_of(:appropriate_body_period_id) }

    it {
      expect(subject).to validate_comparison_of(:appropriate_body_period_id)
      .is_equal_to(appropriate_body_period.id)
      .with_message("does not match the logged-in Appropriate Body")
    }

    it { is_expected.to validate_inclusion_of(:redirect_uri).in_array(client.redirect_uris) }

    context "when the client is unknown" do
      before { authorization_request.client_id = "unknown" }

      it "is invalid" do
        expect(authorization_request).to be_invalid
        expect(authorization_request.errors[:client]).to include("can't be blank")
      end
    end
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:name).to(:client).with_prefix.allow_nil }
  end

  describe "#redirectable?" do
    it { is_expected.to be_redirectable }

    context "when the client is unknown" do
      before { authorization_request.client_id = "unknown" }

      it { is_expected.not_to be_redirectable }
    end

    context "when the redirect URI is not registered with the client" do
      before { authorization_request.redirect_uri = "https://elsewhere.example.com/oauth/callback" }

      it { is_expected.not_to be_redirectable }
    end
  end

  describe "#error_code" do
    it "is nil when the request is valid" do
      authorization_request.validate
      expect(authorization_request.error_code).to be_nil
    end

    it "is invalid_request when a parameter is missing or malformed" do
      authorization_request.response_type = nil
      authorization_request.validate
      expect(authorization_request.error_code).to eq(:invalid_request)

      authorization_request.response_type = "code"
      authorization_request.code_challenge = nil
      authorization_request.validate
      expect(authorization_request.error_code).to eq(:invalid_request)
    end

    context "when the response type is not code" do
      before do
        authorization_request.response_type = "token"
        authorization_request.validate
      end

      it { expect(authorization_request.error_code).to eq(:unsupported_response_type) }
    end

    context "when the Appropriate Body does not match the logged-in one" do
      before do
        authorization_request.appropriate_body_period_id = 0
        authorization_request.validate
      end

      it { expect(authorization_request.error_code).to eq(:access_denied) }
    end
  end

  context "when the client's redirect URI has a query string" do
    let(:client) { FactoryBot.create(:api_oauth_client, redirect_uris: %w[https://vendor.example.com/callback?tenant=1]) }

    before do
      authorization_request.appropriate_body_period_id = 0
      authorization_request.validate
    end

    it "appends the error and state to the redirect URI, keeping the existing query string" do
      expect(authorization_request.redirect_uri_with_params(error: :invalid_request)).to eq(
        "https://vendor.example.com/callback" \
        "?tenant=1" \
        "&error=invalid_request" \
        "&error_description=Appropriate+body+period+does+not+match+the+logged-in+Appropriate+Body" \
        "&state=xyz"
      )
      expect(authorization_request.redirect_uri_with_params(error: :access_denied)).to eq(
        "https://vendor.example.com/callback" \
        "?tenant=1" \
        "&error=access_denied" \
        "&error_description=Appropriate+body+period+does+not+match+the+logged-in+Appropriate+Body" \
        "&state=xyz"
      )
    end

    context "when no state was supplied" do
      before { authorization_request.state = nil }

      it "omits the state from the redirect URI" do
        expect(authorization_request.redirect_uri_with_params(error: :access_denied)).to eq(
          "https://vendor.example.com/callback" \
          "?tenant=1" \
          "&error=access_denied" \
          "&error_description=Appropriate+body+period+does+not+match+the+logged-in+Appropriate+Body"
        )
      end
    end
  end
end
