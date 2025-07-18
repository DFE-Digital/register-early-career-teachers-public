module Schools
  class RegisterMentorWizardController < SchoolsController
    before_action :initialize_wizard, only: %i[new create]
    before_action :reset_wizard, only: :new
    before_action :check_allowed_step, except: %i[start]

    FORM_KEY = :register_mentor_wizard
    WIZARD_CLASS = Schools::RegisterMentorWizard::Wizard.freeze

    def start
      @ect = ECTAtSchoolPeriod.find(params[:ect_id])
      session[:register_mentor_for_ect_id] = @ect.id
      @ect_name = Teachers::Name.new(@ect.teacher).full_name
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
        ect_id: session[:register_mentor_for_ect_id],
        store:
      )
      @ect_name = Teachers::Name.new(@wizard.ect.teacher).full_name
      @mentor = @wizard.mentor
    end

    def check_allowed_step
      redirect_to @wizard.allowed_step_path unless @wizard.allowed_step?
    end

    def current_step
      @current_step ||= request.path.split("/").last.underscore.to_sym.tap do |step_from_path|
        return :not_found unless WIZARD_CLASS.step?(step_from_path)
      end
    end

    def reset_wizard
      @wizard.reset if current_step == :find_mentor
    end

    def store
      @store ||= SessionRepository.new(session:, form_key: FORM_KEY).tap do |store|
        store.update!(school_urn: @school.urn, ect_id: session[:register_mentor_for_ect_id])
      end
    end
  end
end
