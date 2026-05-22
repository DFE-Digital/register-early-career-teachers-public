module Admin::Finance::ActiveLeadProviders
  class StatementsController < Admin::Finance::BaseController
    layout "full"

    before_action :set_active_lead_provider

    def index
      contract_period = @active_lead_provider.contract_period

      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @active_lead_provider.contract_period_year.to_s => admin_contract_period_path(contract_period),
        @active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(contract_period),
      }
      @pagy, @statements = pagy(@active_lead_provider.statements.order(year: :asc, month: :asc))
    end

  private

    def set_active_lead_provider
      @active_lead_provider = ActiveLeadProvider
        .includes(:contract_period, :lead_provider)
        .find(params[:active_lead_provider_id])
    end
  end
end
