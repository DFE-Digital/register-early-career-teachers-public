module Admin
  module Teachers
    class UndoRegistrationWizardController < AdminController
      layout "full"

      FORM_KEY_PREFIX = "admin_teachers_undo_registration_wizard"

      rescue_from ::Teachers::UndoRegistration::ConfirmationMismatchError,
                  with: :redirect_confirmation_mismatch

      before_action :set_teacher
      before_action :reset_store_on_entry
      before_action :initialize_wizard
      before_action :ensure_journey_available
      before_action :check_allowed_step

      def new
        render current_step
      end

      def create
        if @wizard.save_current_step
          redirect_to @wizard.next_step_path
        else
          render current_step, status: :unprocessable_content
        end
      end

    private

      def authorised? = super && current_user.product_team?

      def set_teacher
        @teacher = Teacher.find(params[:teacher_id])
      end

      def ensure_journey_available
        return if @wizard.registration_undone? || @wizard.journey_available?

        redirect_no_periods_to_close
      end

      def check_allowed_step
        if @wizard.registration_undone?
          return if current_step == :confirmation

          return redirect_to @wizard.resolve_step_path(:confirmation)
        end

        redirect_to @wizard.furthest_valid_step_path unless @wizard.valid_path_to_current_step?
      end

      def redirect_no_periods_to_close
        redirect_to admin_teacher_school_path(@teacher),
                    flash: { error: "There are no open periods to close for this registration." }
      end

      def redirect_confirmation_mismatch
        redirect_to @wizard.current_step_path,
                    flash: { error: "The registration has changed. Review the updated details before continuing." }
      end

      def store
        @store ||= DfE::Wizard::Repository::Session.new(session:, key: form_key)
      end

      def form_key
        "#{FORM_KEY_PREFIX}_#{@teacher.id}"
      end

      def current_step
        @current_step ||= request.path.split("/").last.underscore.to_sym
      end

      def initialize_wizard
        @wizard = wizard_class.new(
          current_step:,
          current_step_params: params,
          state_store: UndoRegistrationWizard::StateStore.new(
            repository: store,
            teacher: @teacher,
            author: current_user
          )
        )
      end

      def wizard_class
        Admin::Teachers::UndoRegistrationWizard::Wizard
      end

      def reset_store_on_entry
        return unless current_step == :start
        return if request.referer.to_s.include?("/undo-registration/")

        store.clear
      end
    end
  end
end
