describe LeadProviderDeliveryPartnership do
  describe 'relationships' do
    it { is_expected.to belong_to(:active_lead_provider) }
    it { is_expected.to belong_to(:delivery_partner) }
    it { is_expected.to have_many(:school_partnerships) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_one(:lead_provider).through(:active_lead_provider) }
  end

  describe 'validation' do
    subject { FactoryBot.create(:lead_provider_delivery_partnership) }

    it { is_expected.to validate_presence_of(:active_lead_provider_id).with_message('Select an active lead provider') }
    it { is_expected.to validate_presence_of(:delivery_partner_id).with_message('Select a delivery partner') }
    it { is_expected.to validate_uniqueness_of(:delivery_partner_id).scoped_to(:active_lead_provider_id).with_message('Delivery partner and active lead provider pairing must be unique') }
  end

  describe 'scopes' do
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
    let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
    let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider:) }

    describe '.with_delivery_partner' do
      let(:other_lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership) }

      it 'returns the lead provider delivery partnership belonging to the delivery partner' do
        expect(LeadProviderDeliveryPartnership.with_delivery_partner(delivery_partner)).to include(lead_provider_delivery_partnership)
      end

      it 'does not return lead provider delivery partnerships belonging to other delivery partners' do
        expect(LeadProviderDeliveryPartnership.with_delivery_partner(delivery_partner)).not_to include(other_lead_provider_delivery_partnership)
      end
    end

    describe '.with_active_lead_provider' do
      let(:other_active_lead_provider) { FactoryBot.create(:active_lead_provider) }

      it 'returns the lead provider delivery partnership belonging to the delivery partner' do
        expect(LeadProviderDeliveryPartnership.with_active_lead_provider(active_lead_provider)).to include(lead_provider_delivery_partnership)
      end

      it 'does not return lead provider delivery partnerships belonging to other delivery partners' do
        expect(LeadProviderDeliveryPartnership.with_active_lead_provider(active_lead_provider)).not_to include(other_active_lead_provider)
      end
    end

    describe '.for_contract_period' do
      let(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }
      let(:contract_period_2026) { FactoryBot.create(:contract_period, year: 2026) }
      let(:active_lead_provider_2025) { FactoryBot.create(:active_lead_provider, contract_period: contract_period_2025) }
      let(:active_lead_provider_2026) { FactoryBot.create(:active_lead_provider, contract_period: contract_period_2026) }
      let!(:partnership_2025) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_2025) }
      let!(:partnership_2026) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_2026) }

      it 'returns partnerships for the specified contract period' do
        expect(LeadProviderDeliveryPartnership.for_contract_period(contract_period_2025)).to include(partnership_2025)
      end

      it 'does not return partnerships from other contract periods' do
        expect(LeadProviderDeliveryPartnership.for_contract_period(contract_period_2025)).not_to include(partnership_2026)
      end

      it 'includes the lead provider relationship' do
        result = LeadProviderDeliveryPartnership.for_contract_period(contract_period_2025).first
        expect(result.association(:active_lead_provider)).to be_loaded
        expect(result.active_lead_provider.association(:lead_provider)).to be_loaded
      end
    end
  end

  describe "delegate methods" do
    it { is_expected.to delegate_method(:lead_provider).to(:active_lead_provider) }
    it { is_expected.to delegate_method(:contract_period).to(:active_lead_provider) }
  end

  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: target) }
    let(:target) { FactoryBot.create(:delivery_partner) }

    it_behaves_like "a declarative touch model", on_event: %i[create destroy], timestamp_attribute: :api_updated_at
  end
end
