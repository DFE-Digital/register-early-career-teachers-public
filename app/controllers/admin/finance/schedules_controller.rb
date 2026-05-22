module Admin::Finance
  class SchedulesController < Admin::Finance::BaseController
    layout "full"

    before_action :set_contract_period
    before_action :set_schedule, only: %i[show destroy]
    before_action :redirect_if_contract_period_started, only: %i[new create destroy]

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
      @schedule = Schedule.new
    end

    def create
      @service = Schedules::Create.new(
        author: current_user,
        contract_period_year: @contract_period.year,
        identifier: schedule_params[:identifier]
      )

      if @service.create!
        redirect_to admin_contract_period_schedules_path(@contract_period),
                    alert: "#{@service.schedule.name} schedule added"
      else
        @schedule = @service.schedule
        render :new, status: :unprocessable_content
      end
    rescue ActionController::ParameterMissing
      @schedule = Schedule.new
      @schedule.errors.add(:identifier, "Select a schedule")
      render :new, status: :unprocessable_content
    end

    def destroy
      @service = Schedules::Destroy.new(
        author: current_user,
        schedule: @schedule
      )

      if @service.destroy!
        redirect_to admin_contract_period_schedules_path(@contract_period),
                    alert: "#{@schedule.name} schedule removed"
      else
        redirect_to admin_contract_period_schedule_path(@contract_period, @schedule),
                    alert: "#{@schedule.name} schedule could not be removed"
      end
    end

  private

    def set_contract_period
      @contract_period = ContractPeriod.find(params[:contract_period_id])
    end

    def set_schedule
      @schedule = Schedule.find(params[:id])
    end

    def schedule_params
      params.expect(schedule: %i[identifier])
    end

    def redirect_if_contract_period_started
      return if @contract_period.editable?

      flash[:error] = "Schedules cannot be edited once the contract period has started"
      redirect_to admin_contract_period_schedules_path(@contract_period)
    end
  end
end
