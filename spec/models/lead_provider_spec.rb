describe LeadProvider do
  describe "associations" do
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:active_lead_providers).inverse_of(:lead_provider) }
    it { is_expected.to have_many(:lead_provider_delivery_partnerships).through(:active_lead_providers) }
    it { is_expected.to have_many(:api_tokens).class_name("API::Token") }
  end

  describe "validations" do
    subject { FactoryBot.build(:lead_provider) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.allow_nil }

    describe ".alphabetical" do
      let(:lead_provider1) { FactoryBot.create(:lead_provider, name: "C") }
      let(:lead_provider2) { FactoryBot.create(:lead_provider, name: "A") }
      let(:lead_provider3) { FactoryBot.create(:lead_provider, name: "B") }

      it "returns lead providers in alphabetical order" do
        expect(described_class.alphabetical).to contain_exactly(lead_provider2, lead_provider3, lead_provider1)
      end
    end
  end

  describe "normalizing" do
    subject { FactoryBot.build(:lead_provider, name: " Some lead provider ") }

    it "removes leading and trailing spaces from the name" do
      expect(subject.name).to eql("Some lead provider")
    end
  end
end
