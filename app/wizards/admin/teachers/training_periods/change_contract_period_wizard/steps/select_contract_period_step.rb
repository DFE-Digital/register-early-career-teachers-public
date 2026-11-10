module Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Steps
  class SelectContractPeriodStep
    include DfE::Wizard::Step

    def self.permitted_params = %i[contract_period_year]

    attribute :contract_period_year, :integer

    validates :contract_period_year, presence: { message: "Select a new contract period" }
    validate :contract_period_available

    delegate :state_store, to: :wizard

    def serializable_data = super.merge("school_partnership_id" => nil)

  private

    def contract_period_available
      return if contract_period_year.blank?
      return if state_store.contract_periods.exists?(year: contract_period_year)

      errors.add(:contract_period_year, "Select a new contract period")
    end
  end
end
