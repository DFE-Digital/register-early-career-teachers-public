module Admin::Finance
  class ActiveLeadProvidersController < Admin::Finance::BaseController
    layout "full"

    before_action :set_contract_period
    before_action :redirect_unless_contract_period_editable, only: %i[new create destroy]

    def index
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @contract_period.year.to_s => admin_contract_period_path(@contract_period),
      }
      @editable = @contract_period.editable?
      @framework_agreements = @contract_period
        .framework_agreements
        .with_lead_provider_ordered_by_name
        .includes(:contracts, :statements, :delivery_partners)
    end

    def new
      @framework_agreement = @contract_period.framework_agreements.build
      @available_lead_providers = available_lead_providers
    end

    def create
      @framework_agreement = ::ActiveLeadProviders::Create.new(
        author: current_user,
        contract_period: @contract_period,
        lead_provider_id: framework_agreement_params[:lead_provider_id]
      ).call

      if @framework_agreement.persisted?
        flash[:notice] = "#{@framework_agreement.lead_provider.name} added"
        redirect_to admin_contract_period_active_lead_providers_path(@contract_period)
      else
        @available_lead_providers = available_lead_providers
        render :new, status: :unprocessable_entity
      end
    rescue ::ActiveLeadProviders::SeedFromPrevious::PreviousActiveLeadProviderError,
           ::ActiveLeadProviders::SeedFromPrevious::AlreadyPopulatedError => e
      flash[:error] = "Cannot seed: #{e.message}"
      redirect_to admin_contract_period_active_lead_providers_path(@contract_period)
    end

    def destroy
      framework_agreement = @contract_period.framework_agreements.find(params[:id])
      lead_provider_name = framework_agreement.lead_provider.name
      ::ActiveLeadProviders::CascadeDelete.new(framework_agreement:, author: current_user).call
      flash[:notice] = "#{lead_provider_name} removed"
      redirect_to admin_contract_period_active_lead_providers_path(@contract_period)
    rescue ::ActiveLeadProviders::CascadeDelete::CascadeDeleteError => e
      flash[:error] = "Cannot remove #{lead_provider_name}: #{e.message}"
      redirect_to admin_contract_period_active_lead_providers_path(@contract_period)
    end

  private

    def set_contract_period
      @contract_period = ContractPeriod.find(params[:contract_period_id])
    end

    def redirect_unless_contract_period_editable
      return if @contract_period.editable?

      flash[:error] = "Lead provider framework agreements cannot be changed once the contract period has started"
      redirect_to admin_contract_period_active_lead_providers_path(@contract_period)
    end

    def available_lead_providers
      LeadProvider
        .where.not(id: @contract_period.framework_agreements.select(:lead_provider_id))
        .alphabetical
    end

    def framework_agreement_params
      params.expect(framework_agreement: [:lead_provider_id])
    end
  end
end
