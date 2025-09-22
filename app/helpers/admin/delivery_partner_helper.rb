module Admin
  module DeliveryPartnerHelper
    def delivery_partner_title(delivery_partner)
      base = "Change delivery partner name"

      name = delivery_partner.attribute_in_database(:name).presence

      name ? "#{base} for #{name}" : base
    end
  end
end
