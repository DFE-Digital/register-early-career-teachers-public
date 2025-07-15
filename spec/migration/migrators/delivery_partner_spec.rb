RSpec.describe Migrators::DeliveryPartner do
  it_behaves_like "a migrator", :delivery_partner, [] do
    def create_migration_resource
      FactoryBot.create(:migration_delivery_partner)
    end

    def create_resource(migration_resource)
    end

    def setup_failure_state
      dp = FactoryBot.create(:migration_delivery_partner)
      FactoryBot.create(:delivery_partner, name: dp.name, api_id: SecureRandom.uuid)
    end

    describe "#migrate!" do
      it 'creates a record in the ecf2 database' do
        expect {
          instance.migrate!
        }.to change(::DeliveryPartner, :count).by(Migration::DeliveryPartner.count)
      end

      it "populates the ecf2 model correctly" do
        instance.migrate!

        ::DeliveryPartner.find_each do |delivery_partner|
          source_record = Migration::DeliveryPartner.find(delivery_partner.api_id)
          expect(delivery_partner.name).to eq source_record.name
          expect(delivery_partner.created_at).to eq source_record.created_at
          expect(delivery_partner.updated_at).to eq source_record.updated_at
        end
      end
    end
  end
end
