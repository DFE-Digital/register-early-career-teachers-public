describe ActiveLeadProvider do
  describe "associations" do
    it { is_expected.to belong_to(:contract_period) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to have_many(:statements) }
    it { is_expected.to have_many(:lead_provider_delivery_partnerships) }
    it { is_expected.to have_many(:delivery_partners).through(:lead_provider_delivery_partnerships) }
    it { is_expected.to have_many(:expressions_of_interest).class_name('TrainingPeriod').inverse_of(:expression_of_interest) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.create(:active_lead_provider) }

    it { is_expected.to validate_presence_of(:lead_provider_id).with_message("Choose a lead provider") }
    it { is_expected.to validate_presence_of(:contract_period_id).with_message("Choose a contract period") }
    it { is_expected.to validate_uniqueness_of(:contract_period_id).scoped_to(:lead_provider_id).with_message("Contract period and lead provider must be unique") }
  end

  describe "scopes" do
    let!(:rp_1) { FactoryBot.create(:contract_period) }
    let!(:rp_2) { FactoryBot.create(:contract_period) }
    let!(:lp_1) { FactoryBot.create(:lead_provider) }
    let!(:lp_2) { FactoryBot.create(:lead_provider) }
    let!(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, contract_period: rp_1, lead_provider: lp_1) }
    let!(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, contract_period: rp_1, lead_provider: lp_2) }
    let!(:active_lead_provider_3) { FactoryBot.create(:active_lead_provider, contract_period: rp_2, lead_provider: lp_1) }
    let!(:active_lead_provider_4) { FactoryBot.create(:active_lead_provider, contract_period: rp_2, lead_provider: lp_2) }

    describe ".for_contract_period" do
      it "returns provider partnerships only for the specified academic year" do
        expect(described_class.for_contract_period(rp_1.id)).to contain_exactly(active_lead_provider_1, active_lead_provider_2)
      end
    end

    describe ".for_lead_provider" do
      it "returns provider partnerships only for the specified lead provider" do
        expect(described_class.for_lead_provider(lp_2.id)).to contain_exactly(active_lead_provider_2, active_lead_provider_4)
      end
    end
  end
end
