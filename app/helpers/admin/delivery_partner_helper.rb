module Admin
  module DeliveryPartnerHelper
    def delivery_partner_title(delivery_partner)
      base = "Change delivery partner name"

      name = delivery_partner.attribute_in_database(:name).to_s.squish.presence

      name ? "#{base} for #{name}" : base
    end
  end
end
