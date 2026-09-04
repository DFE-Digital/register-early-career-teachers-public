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

  describe "granting an authorization" do
    let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
    let(:current_user) do
      FactoryBot.build(:appropriate_body_user, dfe_sign_in_organisation_id: appropriate_body_period.dfe_sign_in_organisation_id)
    end

    before { allow(Events::Record).to receive(:record_oauth_authorization_created_event!) }

    it "defaults the author to the current user" do
      Current.set(user: current_user) do
        expect(described_class.new.author).to eq(current_user)
      end
    end

    it "records an event when the authorization is created and not when it changes afterwards" do
      authorization = FactoryBot.create(:api_oauth_authorization, appropriate_body_period:, author: current_user)

      expect(Events::Record).to have_received(:record_oauth_authorization_created_event!).once.with(
        author: current_user, authorization:
      )

      authorization.update!(code_exchanged_at: Time.zone.now)

      expect(Events::Record).to have_received(:record_oauth_authorization_created_event!).once
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
end
