describe LeadProvider do
  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:lead_provider) }

    context "target training periods" do
      let(:framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider: instance) }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement:) }
      let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
      let!(:training_period) { FactoryBot.create(:training_period, school_partnership:) }

      let(:target) { instance.training_periods }

      it_behaves_like "a declarative touch model", when_changing: %i[name], timestamp_attribute: :api_transfer_updated_at
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:framework_agreements).inverse_of(:lead_provider) }
    it { is_expected.to have_many(:lead_provider_delivery_partnerships).through(:framework_agreements) }
    it { is_expected.to have_many(:school_partnerships).through(:lead_provider_delivery_partnerships) }
    it { is_expected.to have_many(:training_periods).through(:school_partnerships) }
    it { is_expected.to have_many(:declarations).through(:training_periods) }
    it { is_expected.to have_many(:api_tokens).class_name("API::Token") }
  end

  describe "validations" do
    subject { FactoryBot.build(:lead_provider) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.allow_nil }
    it { is_expected.to allow_values(true, false).for(:vat_registered) }
    it { is_expected.not_to allow_values(nil, "").for(:vat_registered) }

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
