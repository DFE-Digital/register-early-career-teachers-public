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
end
