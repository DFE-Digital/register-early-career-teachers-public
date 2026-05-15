module Admin::Finance
  class SchedulesController < Admin::Finance::BaseController
    def index
      @contract_period = ContractPeriod.find(params[:contract_period_id])
    end
  end
end
