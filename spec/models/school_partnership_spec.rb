describe SchoolPartnership do
  describe "associations" do
    it { is_expected.to have_many(:events) }
    it { is_expected.to belong_to(:lead_provider_delivery_partnership) }
    it { is_expected.to belong_to(:school) }
    it { is_expected.to have_one(:lead_provider).through(:lead_provider_delivery_partnership) }
    it { is_expected.to have_one(:delivery_partner).through(:lead_provider_delivery_partnership) }
    it { is_expected.to have_one(:registration_period).through(:lead_provider_delivery_partnership) }
  end

  describe "validations" do
    subject { build(:school_partnership) }

    it { is_expected.to validate_presence_of(:school) }
    it { is_expected.to validate_presence_of(:lead_provider_delivery_partnership) }
    it { is_expected.to validate_uniqueness_of(:lead_provider_delivery_partnership).scoped_to(:school_id) }
  end

  describe "scopes" do
    let(:ay_1) { FactoryBot.create(:registration_period) }
    let(:ay_2) { FactoryBot.create(:registration_period) }
    let(:lp_1) { FactoryBot.create(:lead_provider) }
    let(:lp_2) { FactoryBot.create(:lead_provider) }
    let(:dp_1) { FactoryBot.create(:delivery_partner) }
    let(:dp_2) { FactoryBot.create(:delivery_partner) }
    let(:lpap_1) { create(:lead_provider_active_period, lead_provider: lp_1, registration_period: ay_1) }
    let(:lpap_2) { create(:lead_provider_active_period, lead_provider: lp_2, registration_period: ay_1) }
    let(:lpap_3) { create(:lead_provider_active_period, lead_provider: lp_1, registration_period: ay_2) }
    let(:lpdp_1) { create(:lead_provider_delivery_partnership, lead_provider_active_period: lpap_1, delivery_partner: dp_1) }
    let(:lpdp_2) { create(:lead_provider_delivery_partnership, lead_provider_active_period: lpap_1, delivery_partner: dp_2) }
    let(:lpdp_3) { create(:lead_provider_delivery_partnership, lead_provider_active_period: lpap_2, delivery_partner: dp_1) }
    let(:lpdp_4) { create(:lead_provider_delivery_partnership, lead_provider_active_period: lpap_3, delivery_partner: dp_2) }
    let!(:partnership_1) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lpdp_1) }
    let!(:partnership_2) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lpdp_2) }
    let!(:partnership_3) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lpdp_3) }
    let!(:partnership_4) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lpdp_4) }

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
  end
end
