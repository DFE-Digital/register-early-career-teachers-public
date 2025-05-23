describe API::TokenManager do
  describe ".create_lead_provider_api_token!" do
    subject(:create_token) { described_class.create_lead_provider_api_token!(lead_provider:, token:, description:) }

    let(:description) { "A token used for test purposes" }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:token) { "a-token" }

    it { expect { create_token }.to change(API::Token, :count).by(1) }
    it { is_expected.to be_a(API::Token) }
    it { is_expected.to have_attributes(lead_provider:, token:, description:) }

    it "records an event" do
      allow(Events::Record).to receive(:record_lead_provider_api_token_created_event!).once.and_call_original

      api_token = create_token

      expect(Events::Record).to have_received(:record_lead_provider_api_token_created_event!).with(
        author: an_instance_of(Events::SystemAuthor),
        api_token:
      )
    end

    context "when the description is nil" do
      let(:description) { nil }

      it { is_expected.to have_attributes(description: "A lead provider token for #{lead_provider.name}") }
    end

    context "when the token is nil" do
      let(:token) { nil }

      it { is_expected.to have_attributes(token: be_present) }
    end
  end

  describe ".revoke_lead_provider_api_token!" do
    subject(:revoke_token) { described_class.revoke_lead_provider_api_token!(api_token:) }

    let!(:api_token) { FactoryBot.create(:api_token) }

    it "destroys the API token" do
      expect { revoke_token }.to change(API::Token, :count).by(-1)
      expect { api_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "records an event" do
      allow(Events::Record).to receive(:record_lead_provider_api_token_revoked_event!).once.and_call_original

      revoke_token

      expect(Events::Record).to have_received(:record_lead_provider_api_token_revoked_event!).with(
        author: an_instance_of(Events::SystemAuthor),
        api_token:
      )
    end
  end

  describe ".find_lead_provider_api_token" do
    subject(:find_token) { described_class.find_lead_provider_api_token(token: api_token.token) }

    let(:api_token) { FactoryBot.create(:api_token) }

    it { expect { find_token }.to change { api_token.reload.last_used_at }.to be_within(5.seconds).of(Time.current) }
    it { is_expected.to eq(api_token) }

    context "when the API token does not exist" do
      let(:api_token) { FactoryBot.build(:api_token, token: "does-not-exist-yet") }

      it { is_expected.to be_nil }
    end

    context "when a matching, non-lead provider token exists" do
      let(:api_token) do
        API::Token.new(
          lead_provider: nil,
          description: "Non-lead provider token"
        ).tap { |token| token.save!(validate: false) }
      end

      it { is_expected.to be_nil }
    end
  end
end
