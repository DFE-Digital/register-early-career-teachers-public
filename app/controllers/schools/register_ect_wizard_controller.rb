module Schools
  class RegisterECTWizardController < SchoolsController
    before_action :initialize_wizard, only: %i[new create]
    before_action :reset_wizard, only: :new
    before_action :check_allowed_step, except: %i[start]

    FORM_KEY = :register_ect_wizard
    WIZARD_CLASS = Schools::RegisterECTWizard::Wizard.freeze

    def start
    end

    def new
      render current_step
    end

    def create
      if @wizard.save!
        redirect_to @wizard.next_step_path
      else
        render current_step
      end
    end

  private

    def initialize_wizard
      @wizard = WIZARD_CLASS.new(
        current_step:,
        author: current_user,
        step_params: params,
        store:,
        school:
      )
      @ect = @wizard.ect
    end

    def current_step
      request.path.split("/").last.underscore.to_sym.tap do |step_from_path|
        return :not_found unless WIZARD_CLASS.step?(step_from_path)
      end
    end

    def check_allowed_step
      return if @wizard.allowed_step?

      redirect_to @wizard.allowed_step_path
    end

    def reset_wizard
      @wizard.reset if current_step == :find_ect
    end

    def store
      @store ||= SessionRepository.new(session:, form_key: FORM_KEY)
    end
  end
end
