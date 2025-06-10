describe LeadProviderDeliveryPartnership do
  describe 'relationships' do
    it { is_expected.to belong_to(:active_lead_provider) }
    it { is_expected.to belong_to(:delivery_partner) }
    it { is_expected.to have_many(:school_partnerships) }
  end

  describe 'validation' do
    subject { FactoryBot.create(:lead_provider_delivery_partnership) }

    it { is_expected.to validate_presence_of(:active_lead_provider_id).with_message('Select an active lead provider') }
    it { is_expected.to validate_presence_of(:delivery_partner_id).with_message('Select a delivery partner') }
    it { is_expected.to validate_uniqueness_of(:delivery_partner_id).scoped_to(:active_lead_provider_id).with_message('Delivery partner and active lead provider pairing must be unique') }
  end

  describe 'scopes' do
    describe '.with_delivery_partner' do
      it 'selects records with a matching delivery partner id' do
        expect(described_class.with_delivery_partner(1001).to_sql).to end_with('WHERE "lead_provider_delivery_partnerships"."delivery_partner_id" = 1001')
      end
    end

    describe '.with_active_lead_provider' do
      it 'selects records with a matching active_lead_provider_id id' do
        expect(described_class.with_active_lead_provider(2002).to_sql).to end_with('WHERE "lead_provider_delivery_partnerships"."active_lead_provider_id" = 2002')
      end
    end
  end
end
