module Admin
  class InductionPeriodsController < AdminController
    def new
      @induction_period = InductionPeriod.new(teacher:)
    end

    def create
      service = create_induction_period_service

      if service.create_induction_period!
        redirect_to admin_teacher_path(teacher), alert: 'Induction period created successfully'
      else
        @induction_period = service.induction_period
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback
      @induction_period = service.induction_period
      render :new, status: :unprocessable_entity
    end

    def edit
      @induction_period = induction_period
    end

    def update
      service = update_induction_period_service

      service.update_induction_period!
      redirect_to admin_teacher_path(@induction_period.teacher), alert: 'Induction period updated successfully'
    rescue UpdateInductionPeriod::RecordedOutcomeError => e
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
        :appropriate_body_id
      )
    end

    def teacher
      @teacher ||= Teacher.find(params[:teacher_id])
    end

    def induction_period
      @induction_period ||= InductionPeriod.find(params[:id])
    end

    def create_induction_period_service
      InductionPeriods::CreateInductionPeriod.new(
        author: current_user,
        teacher:,
        params: induction_period_params
      )
    end

    def update_induction_period_service
      UpdateInductionPeriod.new(author: current_user, induction_period:, params: induction_period_params)
    end
  end
end
