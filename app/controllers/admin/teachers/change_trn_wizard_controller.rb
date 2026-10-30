module Admin
  module Teachers
    class ChangeTRNWizardController < AdminController
      layout "full"

      FORM_KEY_PREFIX = "admin_teachers_change_trn_wizard"

      rescue_from Admin::Teachers::ChangeTRNWizard::Wizard::TeacherNotDeactivatedError,
                  with: :redirect_teacher_not_deactivated
      rescue_from Admin::Teachers::ChangeTRNWizard::ConfirmStep::ProposedTRNChangedError,
                  with: :redirect_proposed_trn_changed

      rescue_from Admin::Teachers::ChangeTRNWizard::Wizard::IneligibleForReplacementError,
                  with: :redirect_ineligible_for_replacement

      before_action :set_teacher
      before_action :initialize_wizard
      before_action :check_allowed_step

      def new
        render current_step
      end

      def create
        if @wizard.current_step.save!
          redirect_to @wizard.next_step_path
        else
          render current_step, status: :unprocessable_content
        end
      end

    private

      def authorised?
        super && current_user.can_manage_users?
      end

      def set_teacher
        @teacher = Teacher.find(params[:teacher_id])
      end

      def initialize_wizard
        @wizard = wizard_class.new(
          current_step:,
          step_params: params,
          teacher_id: @teacher.id,
          author: current_user,
          store:
        )
      end

      def check_allowed_step
        return head :not_found unless wizard_class.step?(current_step)
        return redirect_teacher_not_deactivated if @wizard.allowed_steps.empty?
        return if @wizard.allowed_step?

        redirect_to @wizard.allowed_step_path
      end

      def redirect_teacher_not_deactivated
        store.reset

        redirect_to admin_teacher_path(@teacher),
                    flash: { error: "This teacher record is no longer deactivated." }
      end

      def redirect_proposed_trn_changed
        redirect_to admin_teacher_change_trn_wizard_confirm_path(@teacher),
                    flash: {
                      error: "The proposed TRN has changed. Review the updated details before continuing."
                    }
      end

      def redirect_ineligible_for_replacement
        store.reset

        redirect_to admin_teacher_change_trn_wizard_enter_trn_path(@teacher),
                    flash: {
                      error: "The teacher records are not eligible for replacement with the supplied TRN. " \
                             "This could be because another teacher redirects to the supplied TRN, " \
                             "or because the supplied TRN is missing or unchanged."
                    }
      end

      def store
        @store ||= SessionRepository.new(
          session:,
          form_key: "#{FORM_KEY_PREFIX}_#{@teacher.id}"
        )
      end

      def current_step
        @current_step ||= request.path.split("/").last.underscore.to_sym
      end

      def wizard_class
        Admin::Teachers::ChangeTRNWizard::Wizard
      end
    end
  end
end
