describe LeadProviderDeliveryPartnership do
  describe 'relationships' do
    it { is_expected.to belong_to(:active_lead_provider) }
    it { is_expected.to belong_to(:delivery_partner) }
    it { is_expected.to have_many(:school_partnerships) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_one(:lead_provider).through(:active_lead_provider) }
    it { is_expected.to have_one(:contract_period).through(:active_lead_provider) }
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
        expect(described_class.with_delivery_partner(delivery_partner)).to include(lead_provider_delivery_partnership)
      end

      it 'does not return lead provider delivery partnerships belonging to other delivery partners' do
        expect(described_class.with_delivery_partner(delivery_partner)).not_to include(other_lead_provider_delivery_partnership)
      end
    end

    describe '.with_active_lead_provider' do
      let(:other_active_lead_provider) { FactoryBot.create(:active_lead_provider) }

      it 'returns the lead provider delivery partnership belonging to the delivery partner' do
        expect(described_class.with_active_lead_provider(active_lead_provider)).to include(lead_provider_delivery_partnership)
      end

      it 'does not return lead provider delivery partnerships belonging to other delivery partners' do
        expect(described_class.with_active_lead_provider(active_lead_provider)).not_to include(other_active_lead_provider)
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
        expect(described_class.for_contract_period(contract_period_2025)).to include(partnership_2025)
      end

      it 'does not return partnerships from other contract periods' do
        expect(described_class.for_contract_period(contract_period_2025)).not_to include(partnership_2026)
      end

      it 'includes the lead provider relationship' do
        result = described_class.for_contract_period(contract_period_2025).first
        expect(result.association(:active_lead_provider)).to be_loaded
        expect(result.active_lead_provider.association(:lead_provider)).to be_loaded
      end
    end

    describe '.active_lead_provider_ids_for' do
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:other_delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
      let(:other_contract_period) { FactoryBot.create(:contract_period, year: 2026) }

      let(:alp_with_partnership) { FactoryBot.create(:active_lead_provider, contract_period:) }
      let(:alp_other_delivery_partner) { FactoryBot.create(:active_lead_provider, contract_period:) }
      let(:alp_other_contract_period) { FactoryBot.create(:active_lead_provider, contract_period: other_contract_period) }
      let(:alp_no_partnership) { FactoryBot.create(:active_lead_provider, contract_period:) }

      let!(:partnership_same_delivery_partner) do
        FactoryBot.create(:lead_provider_delivery_partnership,
                          delivery_partner:,
                          active_lead_provider: alp_with_partnership)
      end

      let!(:partnership_other_delivery_partner) do
        FactoryBot.create(:lead_provider_delivery_partnership,
                          delivery_partner: other_delivery_partner,
                          active_lead_provider: alp_other_delivery_partner)
      end

      let!(:partnership_other_contract_period) do
        FactoryBot.create(:lead_provider_delivery_partnership,
                          delivery_partner:,
                          active_lead_provider: alp_other_contract_period)
      end

      it 'returns active lead provider IDs for the specified delivery partner and contract period' do
        result = described_class.active_lead_provider_ids_for(delivery_partner, contract_period)
        expect(result.pluck(:active_lead_provider_id)).to contain_exactly(alp_with_partnership.id)
      end

      it 'excludes partnerships with other delivery partners' do
        result = described_class.active_lead_provider_ids_for(delivery_partner, contract_period)
        expect(result.pluck(:active_lead_provider_id)).not_to include(alp_other_delivery_partner.id)
      end

      it 'excludes partnerships from other contract periods' do
        result = described_class.active_lead_provider_ids_for(delivery_partner, contract_period)
        expect(result.pluck(:active_lead_provider_id)).not_to include(alp_other_contract_period.id)
      end

      it 'excludes active lead providers with no partnerships' do
        result = described_class.active_lead_provider_ids_for(delivery_partner, contract_period)
        expect(result.pluck(:active_lead_provider_id)).not_to include(alp_no_partnership.id)
      end

      it 'returns a select query that can be used in subqueries' do
        result = described_class.active_lead_provider_ids_for(delivery_partner, contract_period)
        expect(result.to_sql).to include('SELECT')
        expect(result.to_sql).to include('active_lead_provider_id')
      end
    end
  end

  describe "declarative updates" do
    let(:instance) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: target) }
    let!(:target) { FactoryBot.create(:delivery_partner) }

    it_behaves_like "a declarative touch model", on_event: %i[create destroy], timestamp_attribute: :api_updated_at
    it_behaves_like "a declarative metadata model", on_event: %i[create destroy update]
  end
end
