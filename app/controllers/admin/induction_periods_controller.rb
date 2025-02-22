module Admin
  class InductionPeriodsController < AdminController
    include EditableByAdmin

    def edit
      @induction_period = InductionPeriod.find(params[:id])
    end

    def update
      @induction_period = InductionPeriod.find(params[:id])
      service = UpdateInductionPeriodService.new(
        induction_period: @induction_period,
        params: induction_period_params,
        author: current_user,
        editable_by_admin_params: editable_by_admin_params(params.require(:induction_period))
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
  end
end
