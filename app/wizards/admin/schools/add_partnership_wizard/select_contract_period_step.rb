module Admin
  module Schools
    module AddPartnershipWizard
      class SelectContractPeriodStep
        include DfE::Wizard::Step

        attribute :contract_period_year, :integer

        validates :contract_period_year, presence: { message: "Select a contract period" }
        validate :contract_period_available

        def self.permitted_params = %i[contract_period_year]

      private

        def contract_period_available
          return if contract_period_year.blank?
          return if wizard.contract_periods.where(year: contract_period_year).exists?

          errors.add(:contract_period_year, "Select a contract period")
        end
      end
    end
  end
end
