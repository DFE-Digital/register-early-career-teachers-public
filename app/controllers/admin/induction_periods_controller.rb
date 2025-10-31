module Admin
  class InductionPeriodsController < AdminController
    before_action :set_teacher
    before_action :set_induction_period, except: %i[new create]

    def new
      @induction_period = InductionPeriod.new(teacher: @teacher)
    end

    def create
      service = create_induction_period_service

      if service.create_induction_period!
        redirect_to admin_teacher_path(@teacher), alert: 'Induction period created successfully'
      else
        @induction_period = service.induction_period
        render :new, status: :unprocessable_content
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback
      @induction_period = service.induction_period
      render :new, status: :unprocessable_content
    end

    def update
      service = update_induction_period_service
      service.update_induction_period!
      redirect_to admin_teacher_path(@teacher), alert: 'Induction period updated successfully'
    rescue InductionPeriods::UpdateInductionPeriod::RecordedOutcomeError => e
      @induction_period.errors.add(:base, e.message)
      render :edit, status: :unprocessable_content
    rescue ActiveRecord::RecordInvalid
      @induction_period = service.induction_period
      render :edit, status: :unprocessable_content
    end

    def confirm_delete
      @delete_induction = InductionPeriods::DeleteInductionPeriod.new(
        induction_period: @induction_period
      )
    end

    def destroy
      @delete_induction = delete_induction_period_service
      @delete_induction.delete_induction_period!
      redirect_to admin_teacher_path(@teacher), alert: 'Induction period deleted successfully'
    rescue ActiveModel::ValidationError
      render :confirm_delete, status: :unprocessable_content
    rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback => e
      redirect_to admin_teacher_path(@teacher), alert: "Could not delete induction period: #{e.message}"
    end

  private

    def set_teacher
      @teacher = Teacher.includes(:induction_periods).find(params[:teacher_id])
    end

    def set_induction_period
      @induction_period = @teacher.induction_periods.find(params[:id])
    end

    def induction_period_params
      params.expect(
        induction_period: %i[
          started_on
          finished_on
          number_of_terms
          induction_programme
          training_programme
          appropriate_body_id
        ]
      )
    end

    def create_induction_period_service
      InductionPeriods::CreateInductionPeriod.new(
        author: current_user,
        teacher: @teacher,
        params: induction_period_params
      )
    end

    def update_induction_period_service
      InductionPeriods::UpdateInductionPeriod.new(
        author: current_user,
        induction_period: @induction_period,
        params: induction_period_params
      )
    end

    def delete_induction_period_service
      InductionPeriods::DeleteInductionPeriod.new(
        author: current_user,
        induction_period: @induction_period,
        **auditable_params
      )
    end

    def auditable_params
      params.expect(InductionPeriods::DeleteInductionPeriod.auditable_params)
    end
  end
end
