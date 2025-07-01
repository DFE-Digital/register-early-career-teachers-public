module API
  module ContractPeriodFilterable
    extend ActiveSupport::Concern

  protected

    def contract_period_years
      params.dig(:filter, :cohort)
    end
  end
end
