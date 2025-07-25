module API
  module ContractPeriodFilterable
    extend ActiveSupport::Concern

  protected

    def contract_period_years
      params.dig(:filter, :cohort)
    end

    def contract_period
      ContractPeriod.find_by(year: contract_period_years)
    end
  end
end
