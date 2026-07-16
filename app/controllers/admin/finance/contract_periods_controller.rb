module Admin::Finance
  class ContractPeriodsController < Admin::Finance::BaseController
    include ::ContractPeriods

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
      @contract_period = ContractPeriod.new(contract_period_params.merge(enabled: true))

      ActiveRecord::Base.transaction do
        @contract_period.save!
        @contract_period.seed_from_previous!
      end

      redirect_to admin_contract_periods_path, alert: "#{@contract_period.year} Contract period added"
    rescue ActiveRecord::RecordInvalid,
           SeedFromPrevious::AlreadyScheduledError,
           SeedFromPrevious::ContractPeriodStartedError,
           SeedFromPrevious::NoPreviousContractPeriodError => e

      flash[:error] = "Cannot seed contract period: #{e.message}"
      @contract_period = e.record
      render :new, status: :unprocessable_content
    end

    def edit
    end

    def update
      if @contract_period.update(contract_period_params)
        redirect_to admin_contract_periods_path, alert: "#{@contract_period.year} Contract period updated"
      else
        render :edit, status: :unprocessable_content
      end
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
