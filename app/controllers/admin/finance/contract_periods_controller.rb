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

    def show
      @contract_period = ContractPeriod
        .includes(:active_lead_providers, :schedules)
        .find(params[:id])

      @editable = !@contract_period.started_on_or_before_today?
      @has_lead_providers = @contract_period.active_lead_providers.any?
      @has_schedules = @contract_period.schedules.any?

      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @contract_period.year.to_s => nil,
      }
    end
  end
end
