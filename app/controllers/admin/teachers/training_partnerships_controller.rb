module Admin
  module Teachers
    class TrainingPartnershipsController < AdminController
      before_action :set_teacher
      before_action :set_training_period
      before_action :set_school
      before_action :set_available_partnerships
      before_action :set_partnership_options, only: %i[new create]

      def new
        return redirect_to no_other_partnerships_admin_teacher_training_period_partnership_path(@teacher, @training_period) if @available_partnerships.empty?

        @form = change_partnership_form
      end

      def create
        return redirect_to no_other_partnerships_admin_teacher_training_period_partnership_path(@teacher, @training_period) if @available_partnerships.empty?

        @form = change_partnership_form

        if @form.save(author: current_user)
          flash[:alert] = "Partnership updated"
          redirect_to admin_teacher_training_path(@teacher)
        else
          render :new, status: :unprocessable_entity
        end
      end

      def no_other_partnerships
      end

    private

      def set_teacher
        @teacher = Teacher.find(params[:teacher_id])
      end

      def set_training_period
        @training_period = TrainingPeriod.find(params[:training_period_id])

        raise ActiveRecord::RecordNotFound unless @training_period.trainee.teacher_id == @teacher.id
        raise ActionController::BadRequest, "Training period is not eligible for partnership change" unless @training_period.partnership_change_eligible?
      end

      def set_school
        @school = @training_period.trainee.school
      end

      def set_available_partnerships
        @available_partnerships =
          SchoolPartnership
          .includes(lead_provider_delivery_partnership: [:delivery_partner, { active_lead_provider: :lead_provider }])
          .where(school: @school)
          .for_contract_period_year(contract_period_year)
          .where.not(id: @training_period.school_partnership_id)
      end

      def set_partnership_options
        @partnership_options = @available_partnerships.map do |partnership|
          OpenStruct.new(
            id: partnership.id,
            name: "#{partnership.lead_provider.name} & #{partnership.delivery_partner.name}"
          )
        end
      end

      def change_partnership_form
        Admin::Teachers::ChangeTrainingPartnershipForm.new(
          training_period: @training_period,
          available_partnerships: @available_partnerships,
          school_partnership_id: form_params[:school_partnership_id]
        )
      end

      def form_params
        params.fetch(:admin_teachers_change_training_partnership_form, {}).permit(:school_partnership_id)
      end

      def contract_period_year
        (@training_period.contract_period || @training_period.expression_of_interest_contract_period)&.year
      end
    end
  end
end
