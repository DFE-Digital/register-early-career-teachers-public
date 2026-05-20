module Admin::Finance
  class SchedulesController < Admin::Finance::BaseController
    before_action :set_contract_period
    def index
    end

  private

    def set_contract_period
      @contract_period = ContractPeriod.find(params[:contract_period_id])
    end
  end
end
