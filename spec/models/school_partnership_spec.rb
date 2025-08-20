describe SchoolPartnership do
  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:school_partnership) }

    context "target school_partnership" do
      let(:target) { instance }

      def will_change_attribute(attribute_to_change:, new_value:)
        FactoryBot.create(:lead_provider_delivery_partnership, id: new_value) if attribute_to_change == :lead_provider_delivery_partnership
      end

      it_behaves_like "a declarative touch model", when_changing: %i[lead_provider_delivery_partnership_id], timestamp_attribute: :api_updated_at
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:lead_provider_delivery_partnership).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:school) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_one(:active_lead_provider).through(:lead_provider_delivery_partnership) }
    it { is_expected.to have_one(:delivery_partner).through(:lead_provider_delivery_partnership) }
    it { is_expected.to have_one(:contract_period).through(:active_lead_provider) }
    it { is_expected.to have_one(:lead_provider).through(:active_lead_provider) }
  end

  describe "validations" do
    subject { FactoryBot.create(:school_partnership) }

    it { is_expected.to validate_presence_of(:lead_provider_delivery_partnership_id) }
    it { is_expected.to validate_presence_of(:school_id) }
    it { is_expected.to validate_uniqueness_of(:school_id).scoped_to(:lead_provider_delivery_partnership_id).with_message('School and lead provider delivery partnership combination must be unique') }
  end

  describe 'scopes' do
    describe ".for_contract_period" do
      let(:contract_period_1) { FactoryBot.create(:contract_period) }
      let(:contract_period_2) { FactoryBot.create(:contract_period) }
      let(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, contract_period: contract_period_1) }
      let(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, contract_period: contract_period_2) }
      let(:lead_provider_delivery_partnership_1) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_1) }
      let(:lead_provider_delivery_partnership_2) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_2) }
      let!(:school_partnership_1) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership_1) }
      let!(:school_partnership_2) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership_2) }

      it "returns school partnerships only for the specified contract period" do
        expect(described_class.for_contract_period(contract_period_2.id)).to contain_exactly(school_partnership_2)
      end
    end
  end
end
