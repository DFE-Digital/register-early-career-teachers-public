module Admin::Finance
  class ContractPeriodsController < Admin::Finance::BaseController
    layout "full"

    before_action :set_contract_period, only: %i[show edit update]
    before_action :set_contract_period_flags, only: %i[show edit update]
    before_action :redirect_unless_contract_period_editable, only: %i[edit update]

    def index
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => nil,
      }
      page = params[:page].presence
      @pagy, @contract_periods = pagy(ContractPeriod.most_recent_first, page:)
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
      @contract_period = ContractPeriods::Create.new(
        author: current_user,
        params: contract_period_params
      ).create!

      redirect_to admin_contract_periods_path, alert: "#{@contract_period.year} Contract period added"
    rescue ActiveRecord::RecordInvalid,
           ContractPeriods::SeedFromPrevious::AlreadyScheduledError,
           ContractPeriods::SeedFromPrevious::ContractPeriodStartedError,
           ContractPeriods::SeedFromPrevious::NoPreviousContractPeriodError => e

      flash[:error] = "Cannot seed contract period: #{e.message}"
      @contract_period = e.record
      render :new, status: :unprocessable_content
    end

    def edit
    end

    def update
      ContractPeriods::Update.new(
        author: current_user,
        contract_period: @contract_period,
        params: contract_period_params
      ).update!

      redirect_to admin_contract_periods_path, alert: "#{@contract_period.year} Contract period updated"
    rescue ActiveRecord::RecordInvalid,
           ContractPeriods::Update::NotEditable
      render :edit, status: :unprocessable_content
    end

  private

    def set_contract_period
      @contract_period = ContractPeriod.includes(:active_lead_providers, :schedules).find(params[:id])
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

    def redirect_unless_contract_period_editable
      return if @contract_period.editable?

      flash[:error] = "This contract period has started and cannot be edited"
      redirect_to admin_contract_periods_path
    end
  end
end
