module Admin
  class InductionPeriodsController < AdminController
    def edit
      @induction_period = InductionPeriod.find(params[:id])
    end

    def update
      @induction_period = InductionPeriod.find(params[:id])
      service = UpdateInductionPeriodService.new(
        induction_period: @induction_period,
        params: induction_period_params
      )

      if service.call
        redirect_to admin_teacher_path(@induction_period.teacher),
                    notice: "Induction period updated successfully"
      end
    rescue UpdateInductionPeriodService::RecordedOutcomeError, ActiveRecord::RecordInvalid => e
      @induction_period.errors.add(:base, e.message)
      render :edit, status: :unprocessable_entity
    end

  private

    def induction_period_params
      params.require(:induction_period).permit(
        :started_on, :finished_on, :number_of_terms, :induction_programme
      )
    end
  end
end
