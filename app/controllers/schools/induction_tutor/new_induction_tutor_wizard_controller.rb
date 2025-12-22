module Schools
  module InductionTutor
    class NewInductionTutorWizardController < SchoolsController
      before_action :set_school
      before_action :initialize_wizard, only: %i[new create]
      before_action :check_allowed_step, only: %i[new create]

      WIZARD_CLASS = Schools::InductionTutor::NewInductionTutorWizard::Wizard

      def new
        render current_step
      end

      def create
        if @wizard.valid_step?
          @wizard.current_step.save!
          redirect_to @wizard.next_step_path
        else
          render current_step
        end
      end

    private

      def set_school
        @school = current_user.school
      end

      def check_allowed_step
        redirect_to @wizard.allowed_step_path unless @wizard.allowed_step?
      end

      def store
        @store ||= SessionRepository.new(session:, form_key: :new_induction_tutor_wizard)
      end

      def current_step
        @current_step ||= begin
          step = step_name_from_path
          return :not_found unless WIZARD_CLASS.step?(step)

          step
        end
      end

      def step_name_from_path
        request.path.split("/").last.underscore.to_sym
      end

      def initialize_wizard
        redirect_to(root_path) unless @school

        @wizard = WIZARD_CLASS.new(
          current_step:,
          step_params: params,
          author: current_user,
          school_id: @school.id,
          store:
        )
      end
    end
  end
end
