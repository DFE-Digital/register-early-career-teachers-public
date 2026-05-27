module Admin::Finance
  class ContractPeriodsController < Admin::Finance::BaseController
    layout "full"

    before_action :set_contract_period, only: %i[show edit update]
    before_action :set_contract_period_flags, only: %i[show edit update]
    before_action :redirect_if_contract_period_not_editable, only: %i[edit update]

    def index
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => nil,
      }
      page = params[:page].presence
      @pagy, @contract_periods = pagy(ContractPeriod.unscoped.most_recent_first, page:)
    end

    def show
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @contract_period.year.to_s => nil,
      }
    end

    def new
      @contract_period = ContractPeriod.new
    end

    def create
      @service = ContractPeriods::Create.new(
        author: current_user,
        params: contract_period_params
      )

      if @service.create!
        redirect_to admin_contract_periods_path, alert: "#{@service.contract_period.year} Contract period added"
      else
        @contract_period = @service.contract_period
        render :new, status: :unprocessable_content
      end
    rescue ContractPeriods::SeedFromPrevious::AlreadyScheduledError,
           ContractPeriods::SeedFromPrevious::ContractPeriodStartedError,
           ContractPeriods::SeedFromPrevious::NoPreviousContractPeriodError => e
      flash[:error] = "Cannot seed contract period: #{e.message}"
      @contract_period = @service.contract_period
      render :new, status: :unprocessable_content
    end

    def edit
    end

    def update
      @service = ContractPeriods::Update.new(
        author: current_user,
        contract_period: @contract_period,
        params: contract_period_params
      )

      if @service.update!
        redirect_to admin_contract_periods_path, alert: "#{@service.contract_period.year} Contract period updated"
      else
        @contract_period = @service.contract_period
        render :edit, status: :unprocessable_content
      end
    end

  private

    def set_contract_period
      @contract_period = ContractPeriod
        .includes(:active_lead_providers, :schedules)
        .unscoped
        .find(params[:id])
    end

    def contract_period_params
      params.expect(
        contract_period: %i[
          year
          started_on
          finished_on
          detailed_evidence_types_enabled
          mentor_funding_enabled
          uplift_fees_enabled
        ]
      )
    end

    def set_contract_period_flags
      @editable = @contract_period.editable?
      @has_lead_providers = @contract_period.active_lead_providers.any?
      @has_schedules = @contract_period.schedules.any?
    end

    def redirect_if_contract_period_not_editable
      return if @editable

      redirect_to(request.referer || admin_contract_periods_path, notice: "This contract period cannot be edited")
    end
  end
end
