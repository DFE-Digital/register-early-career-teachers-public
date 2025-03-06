module Admin
  class InductionPeriodsController < AdminController
    # before_action :induction_period

    def new
      # only backdated IPs allowed
      @induction_period = InductionPeriod.new(teacher:)
    end

    def create
      # same as current AB
      # appropriate_body = teacher.induction_periods.last.appropriate_body

      @induction_period = InductionPeriod.new(teacher:, **induction_period_params)
      # @induction_period = InductionPeriod.new(teacher:, appropriate_body:, **induction_period_params)

      if @induction_period.save
        redirect_to admin_teacher_path(@induction_period.teacher),
                    notice: "Induction period created successfully"
      else
        render :new
      end
    end

    def edit
      @induction_period = InductionPeriod.find(params[:id])
    end

    def update
      @induction_period = InductionPeriod.find(params[:id])
      service = UpdateInductionPeriodService.new(
        induction_period: @induction_period,
        params: induction_period_params,
        author: current_user
      )

      if service.update_induction!
        redirect_to admin_teacher_path(@induction_period.teacher),
                    notice: "Induction period updated successfully"
      end
    rescue UpdateInductionPeriodService::RecordedOutcomeError => e
      @induction_period.errors.add(:base, e.message)
      render :edit, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_entity
    end

  private

    def induction_period_params
      params.require(:induction_period).permit(
        :started_on, :finished_on, :number_of_terms, :induction_programme
      )
    end

    def teacher
      Teacher.find(params[:teacher_id])
    end
  end
end
