module Admin
  module Teachers
    class UndoRegistrationWizardController < AdminController
      layout "full"

      FORM_KEY_PREFIX = "admin_teachers_undo_registration_wizard"

      include WizardStoreRescuable

      rescue_from ::Teachers::UndoRegistration::NoPeriodsToCloseError,
                  with: :redirect_no_periods_to_close
      rescue_from ::Teachers::UndoRegistration::UndoOutcomeChangedError,
                  with: :redirect_undo_outcome_changed
      rescue_from ::Teachers::UndoRegistration::AffectedPeriodsChangedError,
                  with: :redirect_affected_periods_changed
      rescue_from ::Teachers::UndoRegistration::RegistrationAlreadyUndoneError,
                  with: :redirect_registration_already_undone

      before_action :set_teacher
      before_action :reset_store_on_entry
      before_action :initialize_wizard
      before_action :check_allowed_step

      def new
        render current_step
      end

      def create
        if @wizard.valid_step? && @wizard.current_step.save!
          redirect_to @wizard.next_step_path
        else
          render current_step, status: :unprocessable_content
        end
      end

    private

      def set_teacher
        @teacher = Teacher.find(params[:teacher_id])
      end

      def check_allowed_step
        return if @wizard.allowed_step?
        return redirect_no_periods_to_close if @wizard.allowed_steps.empty?

        redirect_to @wizard.allowed_step_path
      end

      def redirect_no_periods_to_close
        redirect_to admin_teacher_school_path(@teacher),
                    flash: { error: "There are no open periods to close for this registration." }
      end

      def redirect_undo_outcome_changed
        redirect_to @wizard.current_step_path,
                    flash: { error: "The declarations for this registration have changed. Review the updated outcome before continuing." }
      end

      def redirect_affected_periods_changed
        redirect_to @wizard.current_step_path,
                    flash: { error: "The periods for this registration have changed. Review the updated periods before continuing." }
      end

      def redirect_registration_already_undone
        redirect_to admin_teacher_school_path(@teacher),
                    flash: { error: "This registration has already been undone." }
      end

      def store
        @store ||= SessionRepository.new(session:, form_key:)
      end

      def form_key
        "#{FORM_KEY_PREFIX}_#{@teacher.id}"
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
          store:
        )
      end

      def wizard_class
        Admin::Teachers::UndoRegistrationWizard::Wizard
      end

      def reset_store_on_entry
        return unless current_step == :start
        return if request.referer.to_s.include?("/undo-registration/")

        store.reset
      end
    end
  end
end
