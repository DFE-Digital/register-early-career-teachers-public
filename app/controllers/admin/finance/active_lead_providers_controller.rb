module Admin::Finance
  class ActiveLeadProvidersController < Admin::Finance::BaseController
    include ::ActiveLeadProviders

    layout "full"

    before_action :set_contract_period
    before_action :set_active_lead_provider, only: %i[destroy]
    before_action :redirect_unless_contract_period_editable, only: %i[new create destroy]

    def index
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @contract_period.year.to_s => admin_contract_period_path(@contract_period),
      }
      @editable = @contract_period.editable?
      @active_lead_providers = @contract_period
        .active_lead_providers
        .with_lead_provider_ordered_by_name
        .includes(:contracts, :statements, :delivery_partners)
    end

    def new
      @active_lead_provider = @contract_period.active_lead_providers.build
      @available_lead_providers = available_lead_providers
    end

    def create
      @active_lead_provider = Create.(
        author: current_user,
        contract_period: @contract_period,
        lead_provider_id: active_lead_provider_params[:lead_provider_id]
      )

      if @active_lead_provider.persisted?
        flash[:notice] = "#{@active_lead_provider.lead_provider.name} added"
        redirect_to admin_contract_period_active_lead_providers_path(@contract_period)
      else
        @available_lead_providers = available_lead_providers
        render :new, status: :unprocessable_entity
      end
    rescue SeedFromPrevious::PreviousActiveLeadProviderError,
           SeedFromPrevious::AlreadyPopulatedError => e
      flash[:error] = "Cannot seed: #{e.message}"
      redirect_to admin_contract_period_active_lead_providers_path(@contract_period)
    end

    def destroy
      lead_provider_name = @active_lead_provider.lead_provider_name

      CascadeDelete.(active_lead_provider: @active_lead_provider, author: current_user)
      flash[:notice] = "#{lead_provider_name} removed"
      redirect_to admin_contract_period_active_lead_providers_path(@contract_period)
    rescue CascadeDelete::CascadeDeleteError => e
      flash[:error] = "Cannot remove #{lead_provider_name}: #{e.message}"
      redirect_to admin_contract_period_active_lead_providers_path(@contract_period)
    end

  private

    def set_contract_period
      @contract_period = ContractPeriod.find(params[:contract_period_id])
    end

    def set_active_lead_provider
      @active_lead_provider = @contract_period.active_lead_providers.find(params[:id])
    end

    def redirect_unless_contract_period_editable
      return if @contract_period.editable?

      flash[:error] = "Active lead providers cannot be changed once the contract period has started"
      redirect_to admin_contract_period_active_lead_providers_path(@contract_period)
    end

    def available_lead_providers
      LeadProvider
        .where.not(id: @contract_period.active_lead_providers.select(:lead_provider_id))
        .alphabetical
    end

    def active_lead_provider_params
      params.expect(active_lead_provider: [:lead_provider_id])
    end
  end
end
