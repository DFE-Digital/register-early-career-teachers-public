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
    rescue InductionPeriods::UpdateInductionPeriod::RecordedOutcomeError => e
      @induction_period.errors.add(:base, e.message)
      render :edit, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid
      @induction_period = service.induction_period
      render :edit, status: :unprocessable_entity
    end

    def confirm_delete
      @induction_period = induction_period
    end

    def destroy
      @induction_period = induction_period
      service = delete_induction_period_service
      service.delete_induction_period!
      redirect_to admin_teacher_path(@induction_period.teacher), alert: 'Induction period deleted successfully'
    rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback => e
      redirect_to admin_teacher_path(@induction_period.teacher), alert: "Could not delete induction period: #{e.message}"
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

    def create_induction_period_service
      InductionPeriods::CreateInductionPeriod.new(
        author: current_user,
        teacher:,
        params: induction_period_params
      )
    end

    def update_induction_period_service
      InductionPeriods::UpdateInductionPeriod.new(
        author: current_user,
        induction_period:,
        params: induction_period_params
      )
    end

    def delete_induction_period_service
      InductionPeriods::DeleteInductionPeriod.new(
        author: current_user,
        induction_period:
      )
    end
  end
end
