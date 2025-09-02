module Schools
  class ChangeECTNameWizardController < SchoolsController
    before_action :initialize_wizard, only: %i[new create]

    WIZARD_CLASS = Schools::ChangeECTNameWizard::Wizard.freeze

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

    def initialize_wizard
      @wizard = WIZARD_CLASS.new(
        store:,
        current_step:,
        step_params: params,
        author: current_user,
        ect_id: params[:ect_id]
      )
    end

    def current_step
      request.path.split('/').last.underscore.to_sym
    end

    def store
      @store ||= SessionRepository.new(session:, form_key: :change_name_wizard)
    end
  end
end
