module Admin::Finance::ActiveLeadProviders
  class ContractsController < Admin::Finance::BaseController
    layout "full"

    before_action :set_active_lead_provider
    before_action :set_contract, only: %i[show edit update delete destroy]
    before_action :redirect_unless_editable, only: %i[new create edit update delete destroy]

    def index
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @active_lead_provider.contract_period_year.to_s => admin_contract_period_path(@active_lead_provider.contract_period),
        @active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(@active_lead_provider.contract_period),
      }
      @contracts = @active_lead_provider.contracts.includes(:statements).order(:created_at)
    end

    def show
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @active_lead_provider.contract_period_year.to_s => admin_contract_period_path(@active_lead_provider.contract_period),
        @active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(@active_lead_provider.contract_period),
        "Contracts" => admin_contract_period_active_lead_provider_contracts_path(@active_lead_provider.contract_period, @active_lead_provider),
      }
    end

    def new
      @contract = ::Contracts::Build.new(active_lead_provider: @active_lead_provider).call
    end

    def create
      @contract = ::Contracts::Create.new(
        author: current_user,
        active_lead_provider: @active_lead_provider,
        params: contract_params
      ).call

      redirect_to contract_path(@contract), notice: "Contract added"
    rescue ActiveRecord::RecordInvalid => e
      @contract = e.record
      render :new, status: :unprocessable_content
    end

    def edit
      # This is idiomatic Rails, so we need a comment to keep sonarcube happy.
    end

    def update
      ::Contracts::Update.new(
        author: current_user,
        contract: @contract,
        params: contract_params
      ).call

      redirect_to contract_path(@contract), notice: "Contract updated"
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_content
    end

    def delete
      # This is our project specific pattern, so we need a comment to keep sonarcube happy.
    end

    def destroy
      ::Contracts::Destroy.new(author: current_user, contract: @contract).call
      redirect_to contracts_path, notice: "Contract deleted"
    rescue ::Contracts::Destroy::DeletionError => e
      redirect_to contract_path(@contract), flash: { error: e.message }
    end

  private

    def set_active_lead_provider
      @active_lead_provider = ActiveLeadProvider
        .includes(:contract_period, :lead_provider)
        .find(params.expect(:active_lead_provider_id))
    end

    def set_contract
      @contract = @active_lead_provider.contracts
        .includes(:statements, :flat_rate_fee_structure, banded_fee_structure: :band_terms)
        .find(params.expect(:id))
    end

    def redirect_unless_editable
      unless @active_lead_provider.editable?
        redirect_to contracts_path,
                    flash: { error: "Contracts cannot be changed once the contract period has started" }
      end
    end

    def contract_params
      params.expect(
        contract: [
          :contract_type,
          :ecf_contract_version,
          :ecf_mentor_contract_version,
          :vat_rate,
          {
            banded_fee_structure_attributes: [
              :id,
              :recruitment_target,
              :uplift_fee_per_declaration,
              :monthly_service_fee,
              :setup_fee,
              {
                bands_attributes: %i[
                  id
                  min_declarations
                  max_declarations
                  fee_per_declaration
                  output_fee_percentage
                  service_fee_percentage
                  _destroy
                ]
              },
            ],
            flat_rate_fee_structure_attributes: %i[
              id
              recruitment_target
              fee_per_declaration
            ]
          },
        ]
      )
    end

    def contract_path(contract)
      admin_contract_period_active_lead_provider_contract_path(
        @active_lead_provider.contract_period, @active_lead_provider, contract
      )
    end

    def contracts_path
      admin_contract_period_active_lead_provider_contracts_path(
        @active_lead_provider.contract_period, @active_lead_provider
      )
    end
  end
end
