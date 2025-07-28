module AppropriateBodies
  class InductionPeriodsController < AppropriateBodiesController
    def edit
      @induction_period = induction_period
    end

    def update
      service = update_induction_period_service
      service.update_induction_period!
      redirect_to ab_teacher_path(@induction_period.teacher), alert: 'Induction period updated successfully'
    rescue InductionPeriods::UpdateInductionPeriod::RecordedOutcomeError => e
      @induction_period.errors.add(:base, e.message)
      render :edit, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid
      @induction_period = service.induction_period
      render :edit, status: :unprocessable_entity
    end

  private

    def induction_period_params
      params.require(:induction_period).permit(
        :started_on,
        :finished_on,
        :number_of_terms,
        :induction_programme,
        :training_programme,
        :appropriate_body_id
      )
    end

    def teacher
      @teacher ||= Teacher.find(params[:teacher_id])
    end

    def induction_period
      @induction_period ||= InductionPeriod.find(params[:id])
    end

    def update_induction_period_service
      InductionPeriods::UpdateInductionPeriod.new(
        author: current_user,
        induction_period:,
        params: induction_period_params
      )
    end
  end
end
