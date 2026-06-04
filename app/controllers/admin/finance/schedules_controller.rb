module Admin::Finance
  class SchedulesController < Admin::Finance::BaseController
    layout "full"

    before_action :set_contract_period
    before_action :set_schedule, only: %i[show destroy]
    before_action :redirect_unless_contract_period_editable, only: %i[new create destroy]

    def index
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @contract_period.year.to_s => admin_contract_period_path(@contract_period),
        "Schedules" => nil
      }
    end

    def show
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @contract_period.year.to_s => admin_contract_period_path(@contract_period),
        "Schedules" => admin_contract_period_schedules_path(@contract_period),
        @schedule.name => nil
      }
    end

    def new
      @schedule = @contract_period.schedules.build
    end

    def create
      @schedule = Schedules::Create.new(
        author: current_user,
        contract_period_year: @contract_period.year,
        identifier: schedule_params[:identifier]
      ).create!

      redirect_to admin_contract_period_schedules_path(@contract_period),
                  alert: "#{@schedule.name} schedule added"
    rescue ActionController::ParameterMissing
      @schedule = @contract_period.schedules.build
      @schedule.errors.add(:identifier, "Select a schedule")
      render :new, status: :unprocessable_content
    rescue ActiveRecord::RecordInvalid => e
      @schedule = e.record
      render :new, status: :unprocessable_content
    end

    def destroy
      Schedules::Destroy.new(
        author: current_user,
        schedule: @schedule
      ).destroy!

      redirect_to admin_contract_period_schedules_path(@contract_period),
                  alert: "#{@schedule.name} schedule removed"
    rescue ActiveRecord::RecordNotDestroyed,
           ActiveRecord::InvalidForeignKey
      redirect_to admin_contract_period_schedule_path(@contract_period, @schedule),
                  error: "#{@schedule.name} schedule could not be removed"
    end

  private

    def set_contract_period
      @contract_period = ContractPeriod.find(params[:contract_period_id])
    end

    def set_schedule
      @schedule = @contract_period.schedules.find(params[:id])
    end

    def schedule_params
      params.expect(schedule: %i[identifier])
    end

    def redirect_unless_contract_period_editable
      return if @contract_period.editable?

      flash[:error] = "Schedules cannot be edited once the contract period has started"
      redirect_to admin_contract_period_schedules_path(@contract_period)
    end
  end
end
