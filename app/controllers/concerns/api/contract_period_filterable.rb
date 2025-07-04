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

    def contract_periods
      return ContractPeriod.where("year > 2020") if contract_period_years.blank?

      ContractPeriod.where(year: contract_period_years.split(","))
    end
  end
end
