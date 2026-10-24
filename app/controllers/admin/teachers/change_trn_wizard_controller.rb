module Admin
  module Teachers
    class ChangeTRNWizardController < AdminController
      layout "full"

      FORM_KEY_PREFIX = "admin_teachers_change_trn_wizard"

      rescue_from ::Teachers::ReplaceTRN::TeacherNotDeactivatedError,
                  ::Teachers::MergeTRN::TeacherNotDeactivatedError,
                  with: :redirect_teacher_not_deactivated
      rescue_from Admin::Teachers::ChangeTRNWizard::ConfirmStep::ProposedTRNChangedError,
                  with: :redirect_proposed_trn_changed
      rescue_from Admin::Teachers::ChangeTRNWizard::ConfirmMergeStep::ProposedTRNChangedError,
                  with: :redirect_merge_proposal_changed
      rescue_from ::Teachers::MergeTRN::MergeProposalChangedError,
                  with: :redirect_merge_destination_changed
      rescue_from Admin::Teachers::ChangeTRNWizard::Wizard::MergeDestinationChangedError,
                  with: :redirect_merge_destination_changed

      before_action :set_teacher
      before_action :reset_store_on_start, only: :new
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
        return if store.records_merged

        @teacher = Teacher.find(params[:teacher_id])
      end

      def initialize_wizard
        @wizard = wizard_class.new(
          current_step:,
          step_params: params,
          teacher_id: params[:teacher_id],
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

      def redirect_merge_proposal_changed
        redirect_to @wizard.allowed_step_path,
                    flash: {
                      error: "The proposed TRN has changed. Review the updated details before continuing."
                    }
      end

      def redirect_merge_destination_changed
        store.reset

        redirect_to admin_teacher_change_trn_wizard_enter_trn_path(@teacher),
                    flash: {
                      error: "The teacher records have changed. Enter the replacement TRN and review the records again."
                    }
      end

      def reset_store_on_start
        return unless current_step == :enter_trn && params[:start] == "true"

        store.reset
      end

      def store
        @store ||= SessionRepository.new(
          session:,
          form_key: "#{FORM_KEY_PREFIX}_#{params[:teacher_id]}"
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
