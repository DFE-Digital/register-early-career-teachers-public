module Admin::Finance
  class SchedulesController < Admin::Finance::BaseController
    before_action :set_contract_period
    def index
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @contract_period.year.to_s => admin_contract_period_path(@contract_period),
        "Schedules" => nil
      }
    end

  private

    def set_contract_period
      @contract_period = ContractPeriod.unscoped.find(params[:contract_period_id])
    end
  end
end
