module Admin
  module DeliveryPartners
    class ChangeName
      attr_reader :delivery_partner, :author, :proposed_name

      def initialize(delivery_partner:, proposed_name:, author:)
        @delivery_partner = delivery_partner
        @proposed_name    = proposed_name
        @author           = author
      end

      def rename!
        normalized = proposed_name.to_s.squish

        return delivery_partner if delivery_partner.name.to_s.squish.casecmp?(normalized)

        from = delivery_partner.name

        ActiveRecord::Base.transaction do
          delivery_partner.name = normalized
          delivery_partner.save!(context: :rename)

          Events::Record.record_delivery_partner_name_changed_event!(
            delivery_partner:,
            author:,
            from:,
            to: delivery_partner.name
          )
        end

        delivery_partner
      end
    end
  end
end
