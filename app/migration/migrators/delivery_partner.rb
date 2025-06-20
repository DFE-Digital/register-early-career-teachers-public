module Migrators
  class DeliveryPartner < Migrators::Base
    def self.record_count
      delivery_partners.count
    end

    def self.model
      :delivery_partner
    end

    def self.delivery_partners
      ::Migration::DeliveryPartner.all
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::DeliveryPartner.connection.execute("TRUNCATE #{::DeliveryPartner.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.delivery_partners) do |delivery_partner|
        dp = ::DeliveryPartner.find_or_initialize_by(api_id: delivery_partner.id)
        dp.name = delivery_partner.name
        dp.created_at = delivery_partner.created_at
        dp.updated_at = delivery_partner.updated_at
        dp.save!
      end
    end
  end
end
