RSpec.describe Migrators::DeliveryPartner do
  # TODO: would be nice to use the 'it_behaves_like "a migrator"' shared_example but this one is difficult to make fail
  # so the failure handling specs fail

  describe '.record_count' do
    it 'returns the count of delivery partners' do
      create_list(:migration_delivery_partner, 2)
      expect(described_class.record_count).to eq(2)
    end
  end

  describe '.model' do
    it 'returns :delivery_partner' do
      expect(described_class.model).to eq(:delivery_partner)
    end
  end

  describe '.delivery_partners' do
    it 'returns all delivery_partners' do
      delivery_partner = create(:migration_delivery_partner)
      expect(described_class.delivery_partners).to include(delivery_partner)
    end
  end

  describe '.reset!' do
    before do
      create(:delivery_partner)
      allow(Rails.application.config).to receive(:enable_migration_testing).and_return(enable_migration_testing)
    end

    context 'when migration testing is enabled' do
      let(:enable_migration_testing) { true }

      it 'removes all records from the contract_periods table' do
        expect { described_class.reset! }.to change(DeliveryPartner, :count).from(1).to(0)
      end
    end

    context 'when migration testing is disabled' do
      let(:enable_migration_testing) { false }

      it 'does not remove records from the contract_periods table' do
        expect { described_class.reset! }.not_to(change(DeliveryPartner, :count))
      end
    end
  end

  describe '#migrate!' do
    subject { described_class.new(worker: 0) }

    let!(:delivery_partner1) { create(:migration_delivery_partner) }
    let!(:delivery_partner2) { create(:migration_delivery_partner) }
    let!(:data_migration) { create(:data_migration, model: :delivery_partner) }

    before { subject.migrate! }

    it 'creates a delivery partner for each ecf delivery partner' do
      described_class.delivery_partners.find_each do |delivery_partner|
        dp = DeliveryPartner.find_by(api_id: delivery_partner.id)
        expect(dp.name).to eq delivery_partner.name
        expect(dp.created_at).to eq delivery_partner.created_at
        expect(dp.updated_at).to eq delivery_partner.updated_at
      end
    end
  end
end
