describe APIToken do
  describe "associations" do
    it { is_expected.to belong_to(:lead_provider) }
  end

  describe "validations" do
    subject { FactoryBot.build(:api_token) }

    it { is_expected.to validate_presence_of(:lead_provider).with_message("Lead provider must be specified") }
    it { is_expected.to validate_presence_of(:token).with_message("Hashed token must be specified") }
    it { is_expected.to validate_uniqueness_of(:token).with_message("Hashed token must be unique") }
  end

  describe "scopes" do
    describe ".lead_provider_tokens" do
      subject { described_class.lead_provider_tokens }

      let!(:lead_provider_token) { FactoryBot.create(:api_token) }

      before do
        # Contrived example as we only support lead provider tokens at
        # the moment, but provides a safety net for future changes.
        described_class.new(lead_provider: nil, description: "Non-lead provider token").save(validate: false)
      end

      it { is_expected.to contain_exactly(lead_provider_token) }
    end
  end

  describe "has_secure_token" do
    it "generates a 32 character token on create" do
      lead_provider = FactoryBot.create(:lead_provider)
      generated_token = described_class.create!(lead_provider:, description: "Test token").token
      expect(generated_token).to be_present
      expect(generated_token.size).to eq(32)
    end
  end

  describe "encrypts" do
    it "encrypts the token" do
      api_token = FactoryBot.create(:api_token)
      encrypted_token = api_token.token_before_type_cast

      expect(api_token.token).not_to eq(encrypted_token)
    end
  end

  describe ".create_lead_provider_api_token!" do
    subject(:create_token) { described_class.create_lead_provider_api_token!(lead_provider:, token:, description:) }

    let(:description) { "A token used for test purposes" }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:token) { "a-token" }

    it { expect { create_token }.to change(described_class, :count).by(1) }
    it { is_expected.to be_a(described_class) }
    it { is_expected.to have_attributes(lead_provider:, token:, description:) }

    context "when the description is nil" do
      let(:description) { nil }

      it { is_expected.to have_attributes(description: "A lead provider token for #{lead_provider.name}") }
    end

    context "when the token is nil" do
      let(:token) { nil }

      it { is_expected.to have_attributes(token: be_present) }
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
  end
end
