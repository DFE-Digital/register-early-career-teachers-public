module Admin
  class InductionPeriodsController < AdminController
    def new
      @induction_period = InductionPeriod.new(teacher:)
    end

    def create
      @induction_period = InductionPeriod.new(teacher:, **induction_period_params)

      if @induction_period.save
        redirect_to admin_teacher_path(@induction_period.teacher),
                    alert: "Induction period created successfully"
      else
        render :new
      end
    end

    def edit
      @induction_period = InductionPeriod.find(params[:id])
    end

    def update
      @induction_period = InductionPeriod.find(params[:id])
      service = UpdateInductionPeriod.new(
        induction_period: @induction_period,
        params: induction_period_params,
        author: current_user
      )

      if service.update_induction_period!
        redirect_to admin_teacher_path(@induction_period.teacher),
                    alert: "Induction period updated successfully"
      end
    rescue UpdateInductionPeriod::RecordedOutcomeError => e
      @induction_period.errors.add(:base, e.message)
      render :edit, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_entity
    end

  private

    def induction_period_params
      params.require(:induction_period).permit(
        :started_on,
        :finished_on,
        :number_of_terms,
        :induction_programme,
        :appropriate_body_id
      )
    end

    def teacher
      Teacher.find(params[:teacher_id])
    end
  end
end
