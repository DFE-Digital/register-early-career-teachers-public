module Admin
  module Schools
    module AddPartnershipWizard
      class SelectDeliveryPartnerStep < Step
        attribute :delivery_partner_id, :integer

        validates :delivery_partner_id, presence: { message: "Select a delivery partner" }
        validate :delivery_partner_available
        validate :partnership_unique

        def self.permitted_params = %i[delivery_partner_id]

        def previous_step = :select_lead_provider

        def next_step = :check_answers

      private

        def persist
          value = step_params["delivery_partner_id"] || delivery_partner_id
          store.delivery_partner_id = value
        end

        def delivery_partner_available
          return if delivery_partner_id.blank?
          return if wizard.delivery_partners.where(id: delivery_partner_id).exists?

          errors.add(:delivery_partner_id, "Select a delivery partner")
        end

        def partnership_unique
          return if delivery_partner_id.blank?

          partnership = LeadProviderDeliveryPartnership.find_by(
            active_lead_provider: wizard.selected_active_lead_provider,
            delivery_partner_id:
          )
          return if partnership.blank?

          return unless SchoolPartnership.exists?(
            school: wizard.school,
            lead_provider_delivery_partnership: partnership
          )

          errors.add(:base, "Partnership already exists for this school and contract period")
        end
      end
    end
  end
end
