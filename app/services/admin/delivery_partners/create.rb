module Admin
  module DeliveryPartners
    class Create
      attr_reader :name, :author

      def initialize(name:, author:)
        @name   = name
        @author = author
      end

      def create!
        delivery_partner = DeliveryPartner.new(name:)

        ActiveRecord::Base.transaction do
          delivery_partner.save!

          Events::Record.record_delivery_partner_created_event!(
            delivery_partner:,
            author:
          )
        end

        delivery_partner
      end
    end
  end
end
