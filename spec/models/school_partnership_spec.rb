describe SchoolPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:registration_period).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:lead_provider).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:delivery_partner).inverse_of(:school_partnerships) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.create(:school_partnership) }

    it { is_expected.to validate_presence_of(:registration_period_id) }
    it { is_expected.to validate_presence_of(:lead_provider_id) }
    it { is_expected.to validate_presence_of(:delivery_partner_id) }

    context "uniqueness of registration_period scoped to lead_provider_id and delivery_partner_id" do
      context "when the provider partnership matches the lead_provider_id, delivery_partner_id and registration_period values
               of an existing provider partnership" do
        subject { FactoryBot.build(:school_partnership, registration_period_id:, lead_provider_id:, delivery_partner_id:) }

        let!(:existing_partnership) { FactoryBot.create(:school_partnership) }
        let(:registration_period_id) { existing_partnership.registration_period_id }
        let(:lead_provider_id) { existing_partnership.lead_provider_id }
        let(:delivery_partner_id) { existing_partnership.delivery_partner_id }

        before do
          subject.valid?
        end

        it "add an error" do
          expect(subject.errors.messages).to include(registration_period_id: ["has already been added"])
        end
      end
    end
  end

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
        expect(described_class.for_registration_period(ay_1.id)).to match_array([partnership_1, partnership_2, partnership_3])
      end
    end

    describe ".for_lead_provider" do
      it "returns provider partnerships only for the specified lead provider" do
        expect(described_class.for_lead_provider(lp_2.id)).to match_array([partnership_3])
      end
    end

    describe ".for_delivery_partner" do
      it "returns provider partnerships only for the specified delivery partner" do
        expect(described_class.for_delivery_partner(dp_1.id)).to match_array([partnership_1, partnership_3])
      end
    end
  end
end
