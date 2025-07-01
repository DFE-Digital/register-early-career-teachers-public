describe SchoolPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:lead_provider_delivery_partnership).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:school) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_one(:active_lead_provider).through(:lead_provider_delivery_partnership) }
    it { is_expected.to have_one(:registration_period).through(:active_lead_provider) }
  end

  describe "validations" do
    subject { FactoryBot.create(:school_partnership) }

    it { is_expected.to validate_presence_of(:lead_provider_delivery_partnership_id) }
    it { is_expected.to validate_presence_of(:school_id) }
    it { is_expected.to validate_uniqueness_of(:school_id).scoped_to(:lead_provider_delivery_partnership_id).with_message('School and lead provider delivery partnership combination must be unique') }
  end

  describe 'scopes' do
    describe '.earliest_first' do
      let!(:school_partnership_first) { FactoryBot.create(:school_partnership, created_at: 3.weeks.ago) }
      let!(:school_partnership_second) { FactoryBot.create(:school_partnership, created_at: 2.weeks.ago) }
      let!(:school_partnership_third) { FactoryBot.create(:school_partnership, created_at: 1.week.ago) }

      it 'orders with earliest created records first' do
        expect(SchoolPartnership.earliest_first).to eq([
          school_partnership_first,
          school_partnership_second,
          school_partnership_third,
        ])
      end
    end

    describe ".for_registration_period" do
      let(:registration_period_1) { FactoryBot.create(:registration_period) }
      let(:registration_period_2) { FactoryBot.create(:registration_period) }
      let(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, registration_period: registration_period_1) }
      let(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, registration_period: registration_period_2) }
      let(:lead_provider_delivery_partnership_1) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_1) }
      let(:lead_provider_delivery_partnership_2) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_2) }
      let!(:school_partnership_1) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership_1) }
      let!(:school_partnership_2) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership_2) }

      it "returns school partnerships only for the specified registration period" do
        expect(described_class.for_registration_period(registration_period_2.id)).to contain_exactly(school_partnership_2)
      end
    end
  end
end
