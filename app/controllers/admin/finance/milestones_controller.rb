module Admin::Finance
  class MilestonesController < Admin::Finance::BaseController
    before_action :set_contract_period
    before_action :set_schedule
    before_action :set_milestone, only: %i[destroy]
    before_action :redirect_unless_contract_period_editable

    def new
      @milestone = @schedule.milestones.build
    end

    def create
      @milestone = Milestones::Create.new(
        author: current_user,
        schedule: @schedule,
        params: milestone_params
      ).create!

      redirect_to admin_contract_period_schedule_path(@contract_period, @schedule),
                  alert: "#{@milestone.declaration_type.titleize} milestone added"
    rescue ActiveRecord::RecordInvalid => e
      @milestone = e.record
      render :new, status: :unprocessable_content
    end

    def destroy
      Milestones::Destroy.new(
        author: current_user,
        milestone: @milestone
      ).destroy!

      redirect_to admin_contract_period_schedule_path(@contract_period, @schedule),
                  alert: "#{@milestone.declaration_type.titleize} milestone removed"
    rescue ActiveRecord::RecordNotDestroyed,
           ActiveRecord::InvalidForeignKey
      redirect_to admin_contract_period_schedule_path(@contract_period, @schedule),
                  error: "#{@milestone.declaration_type.titleize} milestone could not be removed"
    end

  private

    def set_contract_period
      @contract_period = ContractPeriod.find(params[:contract_period_id])
    end

    def set_schedule
      @schedule = @contract_period.schedules.find(params[:schedule_id])
    end

    def set_milestone
      @milestone = @schedule.milestones.find(params[:id])
    end

    def milestone_params
      params.expect(milestone: %i[declaration_type start_date milestone_date])
    end

    def redirect_unless_contract_period_editable
      return if @contract_period.editable?

      flash[:error] = "Milestones cannot be edited once the contract period has started"
      redirect_to admin_contract_period_schedule_path(@contract_period, @schedule)
    end
  end
end
