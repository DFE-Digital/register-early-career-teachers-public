describe SchoolPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:delivery_partner).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:available_provider_pairing).inverse_of(:school_partnerships) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.create(:school_partnership) }

    it { is_expected.to validate_presence_of(:delivery_partner_id) }

  describe "scopes" do
    let!(:ay_1) { FactoryBot.create(:registration_period) }
    let!(:ay_2) { FactoryBot.create(:registration_period) }
    let!(:lp_1) { FactoryBot.create(:lead_provider) }
    let!(:lp_2) { FactoryBot.create(:lead_provider) }
    let!(:dp_1) { FactoryBot.create(:delivery_partner) }
    let!(:dp_2) { FactoryBot.create(:delivery_partner) }
    let!(:partnership_1) { FactoryBot.create(:school_partnership, registration_period: ay_1, lead_provider: lp_1, delivery_partner: dp_1) }
    let!(:partnership_2) { FactoryBot.create(:school_partnership, registration_period: ay_1, lead_provider: lp_1, delivery_partner: dp_2) }
    let!(:partnership_3) { FactoryBot.create(:school_partnership, registration_period: ay_1, lead_provider: lp_2, delivery_partner: dp_1) }
    let!(:partnership_4) { FactoryBot.create(:school_partnership, registration_period: ay_2, lead_provider: lp_1, delivery_partner: dp_2) }

    describe ".for_registration_period" do
      it "returns provider partnerships only for the specified academic year" do
        expect(described_class.for_registration_period(ay_1.id)).to contain_exactly(partnership_1, partnership_2, partnership_3)
      end
    end

    describe ".for_lead_provider" do
      it "returns provider partnerships only for the specified lead provider" do
        expect(described_class.for_lead_provider(lp_2.id)).to contain_exactly(partnership_3)
      end
    end

    describe ".for_delivery_partner" do
      it "returns provider partnerships only for the specified delivery partner" do
        expect(described_class.for_delivery_partner(dp_1.id)).to contain_exactly(partnership_1, partnership_3)
      end
    end
    it { is_expected.to validate_presence_of(:available_provider_pairing_id) }
  end
end
