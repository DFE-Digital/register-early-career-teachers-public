class Schools::AssignExistingMentorWizardController < SchoolsController
  include Schools::InductionRedirectable
  
  before_action :initialize_wizard, only: %i[new create]
  before_action :check_allowed_step, only: %i[new create]

  WIZARD_CLASS = Schools::AssignExistingMentorWizard::Wizard

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

  def check_allowed_step
    redirect_to @wizard.allowed_step_path unless @wizard.allowed_step?
  end

  def store
    @store ||= SessionRepository.new(session:, form_key: :assign_existing_mentor_wizard)
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
    redirect_to(root_path) unless store.ect_id && store.mentor_period_id

    @wizard = WIZARD_CLASS.new(
      current_step:,
      step_params: params,
      author: current_user,
      ect_id: store.ect_id,
      mentor_period_id: store.mentor_period_id,
      store:
    )
  end
end
