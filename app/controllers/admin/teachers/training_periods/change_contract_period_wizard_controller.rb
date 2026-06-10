module Admin
  module Teachers
    module TrainingPeriods
      class ChangeContractPeriodWizardController < AdminController
        layout "full"

        FORM_KEY_PREFIX = "admin_teachers_training_periods_change_contract_period_wizard"

        include WizardStoreRescuable

        before_action :set_teacher
        before_action :set_training_period
        before_action :ensure_changeable_training_period
        before_action :initialize_wizard
        before_action :check_allowed_step
        before_action :reset_store_on_entry

        def new
          render current_step
        end

        def create
          if @wizard.valid_step?
            @wizard.current_step.save!

            if current_step == :select_partnership
              render current_step
            else
              redirect_to @wizard.next_step_path
            end
          else
            render current_step, status: :unprocessable_content
          end
        end

      private

        def set_teacher
          @teacher = Teacher.find(params[:teacher_id])
        end

        def set_training_period
          @training_period = TrainingPeriod.find(params[:training_period_id])

          raise ActiveRecord::RecordNotFound unless @training_period.teacher_id == @teacher.id
        end

        def ensure_changeable_training_period
          unless ChangeContractPeriod::Eligibility.new(training_period: @training_period).eligible?
            raise ActionController::BadRequest,
                  "Training period is not eligible for contract period change"
          end
        end

        def check_allowed_step
          redirect_to @wizard.allowed_step_path unless @wizard.allowed_step?
        end

        def store
          @store ||= SessionRepository.new(session:, form_key:)
        end

        def form_key
          "#{FORM_KEY_PREFIX}_#{@teacher.id}_#{@training_period.id}"
        end

        def current_step
          @current_step ||= begin
            step = step_name_from_path
            return :not_found unless wizard_class.step?(step)

            step
          end
        end

        def step_name_from_path
          request.path.split("/").last.underscore.to_sym
        end

        def initialize_wizard
          @wizard = wizard_class.new(
            current_step:,
            step_params: params,
            author: current_user,
            teacher_id: @teacher.id,
            training_period_id: @training_period.id,
            store:
          )
        end

        def wizard_class
          Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard
        end

        def reset_store_on_entry
          return unless current_step == :select_contract_period
          return if request.referer.to_s.include?("/contract-period/change/")

          store.reset
        end
      end
    end
  end
end
