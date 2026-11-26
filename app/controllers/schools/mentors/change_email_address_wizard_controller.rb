module Schools
  module Mentors
    class ChangeEmailAddressWizardController < SchoolsController
      include Schools::InductionRedirectable

      FORM_KEY_PREFIX = "schools_mentors_change_email_address_wizard"

      before_action :set_mentor_at_school_period
      before_action :reset_store_on_entry, only: :new
      before_action :initialize_wizard
      before_action :reject_incomplete_check_answers, only: :create, if: -> { current_step == :check_answers }
      before_action :check_allowed_step

      def new
        render @current_step
      end

      def create
        if @wizard.save_current_step
          redirect_to @wizard.next_step_path
        else
          render @current_step, status: :unprocessable_content
        end
      end

    private

      def set_mentor_at_school_period
        @mentor_at_school_period = @school.mentor_at_school_periods.find(params[:mentor_id])
      end

      def store
        @store ||= DfE::Wizard::Repository::Session.new(session:, key: form_key)
      end

      def form_key
        "#{FORM_KEY_PREFIX}_#{@mentor_at_school_period.id}"
      end

      def current_step
        @current_step ||= request.path.split("/").last.underscore.to_sym
      end

      def initialize_wizard
        @wizard = wizard_class.new(
          current_step:,
          current_step_params: params,
          state_store: ChangeEmailAddressWizard::StateStore.new(
            repository: store,
            mentor_at_school_period: @mentor_at_school_period
          )
        )
      end

      def wizard_class
        ChangeEmailAddressWizard::Wizard
      end

      def check_allowed_step
        return if @wizard.valid_path_to_current_step?

        redirect_to @wizard.furthest_valid_step_path
      end

      def reject_incomplete_check_answers
        return if @wizard.state_store.details_changed?

        redirect_to @wizard.resolve_step_path(@wizard.root_step),
                    flash: { error: WizardStoreRescuable::EMPTY_STORE_FLASH_MESSAGE }
      end

      def reset_store_on_entry
        return unless current_step == :edit
        return if request.referer.to_s.include?("/change-email-address/")

        store.clear
      end
    end
  end
end
