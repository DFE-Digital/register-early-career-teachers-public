describe API::OAuth::Authorization do
  describe "associations" do
    it { is_expected.to belong_to(:client) }
    it { is_expected.to belong_to(:appropriate_body_period) }
  end

  describe "enums" do
    it {
      expect(subject).to(
        define_enum_for(:code_challenge_method)
          .with_values(s256: "S256")
          .backed_by_column_of_type(:enum)
          .validating
      )
    }
  end

  describe "validations" do
    subject(:authorization) { FactoryBot.build(:api_oauth_authorization) }

    it { is_expected.to validate_presence_of(:client) }
    it { is_expected.to validate_presence_of(:appropriate_body_period) }
    it { is_expected.to validate_presence_of(:redirect_uri) }
    it { is_expected.to validate_presence_of(:code_challenge) }
    it { is_expected.not_to validate_presence_of(:token_expires_at) }

    context "using a persisted record as the matcher's own insert would skip the code assignment" do
      subject(:authorization) { FactoryBot.create(:api_oauth_authorization) }

      it { is_expected.to validate_uniqueness_of(:token_digest).allow_nil }
    end

    context "when a token has been issued" do
      subject(:authorization) { FactoryBot.build(:api_oauth_authorization).tap(&:assign_token) }

      it { is_expected.to validate_presence_of(:token_expires_at) }
    end

    context "when the redirect URI is not registered with the client" do
      before { authorization.redirect_uri = "https://elsewhere.example.com/oauth/callback" }

      it "is invalid" do
        expect(authorization).not_to be_valid
        expect(authorization.errors[:redirect_uri]).to include("is not included in the list")
      end
    end

    context "when the client's redirect URIs change after the authorization is created" do
      subject(:authorization) { FactoryBot.create(:api_oauth_authorization) }

      before { authorization.client.update!(redirect_uris: %w[https://elsewhere.example.com/oauth/callback]) }

      it "remains valid" do
        expect(authorization.reload).to be_valid
      end
    end
  end

  context "when a code is assigned" do
    it "exposes the code, storing its digest and expiring it 10 minutes later" do
      freeze_time do
        authorization = FactoryBot.create(:api_oauth_authorization)

        expect(authorization.code).to be_present
        expect(authorization.code_digest).to eq(Digest::SHA256.hexdigest(authorization.code))
        expect(authorization.code_expires_at).to eq(10.minutes.from_now)
      end
    end

    context "when the code expiry has passed" do
      subject(:authorization) { FactoryBot.create(:api_oauth_authorization) }

      before { travel_to(authorization.code_expires_at + 1.second) }

      it { is_expected.to be_code_expired }
    end
  end

  context "when a token is assigned" do
    subject(:authorization) { described_class.new }

    it "exposes the token, storing its digest and expiring it 1 year later" do
      freeze_time do
        authorization.assign_token

        expect(authorization.token).to be_present
        expect(authorization.token_digest).to eq(Digest::SHA256.hexdigest(authorization.token))
        expect(authorization.token_expires_at).to eq(1.year.from_now)
      end
    end

    context "when the token expiry has passed" do
      before do
        authorization.assign_token
        travel_to(authorization.token_expires_at + 1.second)
      end

      it { is_expected.to be_token_expired }
    end
  end

  describe "#seconds_to_token_expiration" do
    subject(:authorization) { FactoryBot.build(:api_oauth_authorization) }

    it "returns the number of seconds until the token expires" do
      authorization.assign_token
      authorization.token_expires_at = 1.day.from_now
      expect(authorization.seconds_to_token_expiration).to be_within(1.second).of(1.day.to_i)
    end

    context "when there is no token" do
      it "returns nil" do
        expect(authorization.seconds_to_token_expiration).to be_nil
      end
    end

    context "when the token has expired" do
      # It should never happen in a real interaction but we could call this method on an existing
      # authorization so we should return something sensible.  The OAuth spec doesn't specify this.
      it "returns zero" do
        authorization.assign_token
        authorization.token_expires_at = 1.day.ago

        expect(authorization.seconds_to_token_expiration).to be_zero
      end
    end
  end
end
