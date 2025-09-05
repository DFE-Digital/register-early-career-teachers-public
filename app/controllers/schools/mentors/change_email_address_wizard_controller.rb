module Schools
  module Mentors
    class ChangeEmailAddressWizardController < SchoolsController
      before_action :set_mentor, :set_wizard
      before_action :reset_wizard, only: :new

      FORM_KEY = :schools_mentor_change_email_address_wizard
      WIZARD_CLASS = ChangeEmailAddressWizard::Wizard

      def new
        render current_step
      end

      def create
        if @wizard.save!
          redirect_to @wizard.next_step_path
        else
          render current_step, status: :unprocessable_content
        end
      end

    private

      def set_mentor
        @mentor = @school.mentor_at_school_periods.find(params[:mentor_id])
      end

      def set_wizard
        @wizard = WIZARD_CLASS.new(
          current_step:,
          author: current_user,
          step_params: params,
          store:,
          school: @school,
          mentor: @mentor
        )
      end

      def current_step
        @current_step ||= request.path.split("/").last.underscore.to_sym.tap do |step_from_path|
          redirect_to "/404" unless WIZARD_CLASS.step?(step_from_path)
        end
      end

      def reset_wizard
        @wizard.reset! if current_step == :edit
      end

      def store
        @store ||= SessionRepository.new(session:, form_key: FORM_KEY)
      end
    end
  end
end
