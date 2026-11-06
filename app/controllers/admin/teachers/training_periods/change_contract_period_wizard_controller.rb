module Admin
  module Teachers
    module TrainingPeriods
      class ChangeContractPeriodWizardController < AdminController
        layout "full"

        FORM_KEY_PREFIX = "admin_teachers_training_periods_change_contract_period_wizard"

        before_action :set_teacher
        before_action :set_training_period
        before_action :ensure_changeable_training_period
        before_action :reset_store_on_entry
        before_action :initialize_wizard
        before_action :check_allowed_step

        def new
          render current_step
        end

        def create
          unless @wizard.save_current_step
            return render current_step, status: :unprocessable_content
          end

          if current_step == :check_answers
            store.clear
            redirect_to admin_teacher_training_path(@teacher), alert: "Contract period changed"
          else
            redirect_to @wizard.next_step_path
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
          redirect_to @wizard.furthest_valid_step_path unless @wizard.valid_path_to_current_step?
        end

        def store
          @store ||= DfE::Wizard::Repository::Session.new(session:, key: form_key)
        end

        def form_key
          "#{FORM_KEY_PREFIX}_#{@teacher.id}_#{@training_period.id}"
        end

        def current_step
          @current_step ||= request.path.split("/").last.underscore.to_sym
        end

        def initialize_wizard
          @wizard = wizard_class.new(
            current_step:,
            current_step_params: params,
            state_store: ChangeContractPeriodWizard::StateStore.new(repository: store, training_period: @training_period)
          )
        end

        def wizard_class
          Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard
        end

        def reset_store_on_entry
          return unless current_step == :select_contract_period
          return if request.referer.to_s.include?("/contract-period/change/")

          store.clear
        end
      end
    end
  end
end
