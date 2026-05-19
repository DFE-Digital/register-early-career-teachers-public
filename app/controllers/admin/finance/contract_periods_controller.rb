module Admin::Finance
  class ContractPeriodsController < Admin::Finance::BaseController
    layout "full"

    def index
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => nil,
      }
      page = params[:page].presence
      @pagy, @contract_periods = pagy(ContractPeriod.most_recent_first, page:)
    end
  end
end
