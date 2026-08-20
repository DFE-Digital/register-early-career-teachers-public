module Admin
  module Schools
    module AddPartnershipWizard
      class SelectLeadProviderStep < Step
        attribute :framework_agreement_id, :integer

        validates :framework_agreement_id, presence: { message: "Select a lead provider" }
        validate :framework_agreement_available

        def self.permitted_params = %i[framework_agreement_id]

        def previous_step = :select_contract_period

        def next_step = :select_delivery_partner

      private

        def persist
          value = step_params["framework_agreement_id"] || framework_agreement_id
          store.framework_agreement_id = value
          store.delivery_partner_id = nil
        end

        def framework_agreement_available
          return if framework_agreement_id.blank?
          return if wizard.framework_agreements.where(id: framework_agreement_id).exists?

          errors.add(:framework_agreement_id, "Select a lead provider")
        end
      end
    end
  end
end
