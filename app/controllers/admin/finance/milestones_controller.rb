module Admin::Finance
  class MilestonesController < Admin::Finance::BaseController
    before_action :set_contract_period
    before_action :set_schedule
    before_action :redirect_unless_contract_period_editable

    def new
      @milestone = @schedule.milestones.build
    end

    def create
      @service = Milestones::Create.new(
        author: current_user,
        schedule: @schedule,
        params: milestone_params
      )

      if @service.create!
        redirect_to admin_contract_period_schedule_path(@contract_period, @schedule),
                    alert: "#{@service.milestone.declaration_type.titleize} milestone added"
      else
        @milestone = @service.milestone
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      @service = Milestones::Destroy.new(
        author: current_user,
        milestone: @schedule.milestones.find(params[:id])
      )

      if @service.destroy!
        redirect_to admin_contract_period_schedule_path(@contract_period, @schedule),
                    alert: "#{@service.milestone.declaration_type.titleize} milestone removed"
      else
        redirect_to admin_contract_period_schedule_path(@contract_period, @schedule),
                    alert: "#{@service.milestone.declaration_type.titleize} milestone could not be removed"
      end
    end

  private

    def set_contract_period
      @contract_period = ContractPeriod.find(params[:contract_period_id])
    end

    def set_schedule
      @schedule = @contract_period.schedules.find(params[:schedule_id])
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
