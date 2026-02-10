module Admin
  module Schools
    module AddPartnershipWizard
      class SelectLeadProviderStep < Step
        attribute :active_lead_provider_id, :integer

        validates :active_lead_provider_id, presence: { message: "Select a lead provider" }
        validate :active_lead_provider_available

        def self.permitted_params = %i[active_lead_provider_id]

        def previous_step = :select_contract_period

        def next_step = :select_delivery_partner

      private

        def persist
          value = step_params["active_lead_provider_id"] || active_lead_provider_id
          store.active_lead_provider_id = value
          store.delivery_partner_id = nil
        end

        def active_lead_provider_available
          return if active_lead_provider_id.blank?
          return if wizard.active_lead_providers.where(id: active_lead_provider_id).exists?

          errors.add(:active_lead_provider_id, "Select a lead provider")
        end
      end
    end
  end
end
