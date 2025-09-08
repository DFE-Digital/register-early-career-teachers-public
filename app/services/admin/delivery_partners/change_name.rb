module Admin
  module DeliveryPartners
    class ChangeName
      class ValidationError < StandardError; end

      attr_reader :delivery_partner, :author, :proposed_name

      def initialize(delivery_partner:, proposed_name:, author:)
        @delivery_partner = delivery_partner
        @proposed_name    = proposed_name
        @author           = author
      end

      def rename!
        normalized = proposed_name.to_s.squish

        if normalized.blank?
          delivery_partner.errors.add(:name, "Enter the new name for #{delivery_partner.name}")
          raise ValidationError, "Blank name"
        end

        if ::DeliveryPartner.where("LOWER(name) = ?", normalized.downcase)
                            .where.not(id: delivery_partner.id)
                            .exists?
          delivery_partner.errors.add(:name, "A delivery partner with this name already exists")
          raise ValidationError, "Duplicate name"
        end

        return delivery_partner if delivery_partner.name.to_s.squish.casecmp?(normalized)

        from = delivery_partner.name

        ActiveRecord::Base.transaction do
          delivery_partner.update!(name: normalized)
          Events::Record.record_delivery_partner_name_changed_event!(
            delivery_partner:, author:, from:, to: normalized
          )
        end
        delivery_partner
      end
    end
  end
end
