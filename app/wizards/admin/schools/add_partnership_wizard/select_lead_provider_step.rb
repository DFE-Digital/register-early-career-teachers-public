module Admin
  module Schools
    module AddPartnershipWizard
      class SelectLeadProviderStep
        include DfE::Wizard::Step

        attribute :framework_agreement_id, :integer

        validates :framework_agreement_id, presence: { message: "Select a lead provider" }
        validate :framework_agreement_available

        def self.permitted_params = %i[framework_agreement_id]

      private

        def framework_agreement_available
          return if framework_agreement_id.blank?
          return if wizard.framework_agreements.where(id: framework_agreement_id).exists?

          errors.add(:framework_agreement_id, "Select a lead provider")
        end
      end
    end
  end
end
