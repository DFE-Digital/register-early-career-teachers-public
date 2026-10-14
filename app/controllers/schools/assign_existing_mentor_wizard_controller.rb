class Schools::AssignExistingMentorWizardController < SchoolsController
  include Schools::RegistrationWindowRedirectable
  include Schools::InductionRedirectable

  before_action :ensure_wizard_started
  before_action :initialize_wizard

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

  def ensure_wizard_started
    redirect_to(schools_ects_home_path) unless state_store.started?
  end

  def state_store
    @state_store ||= Schools::AssignExistingMentorWizard::StateStore.new(
      repository: DfE::Wizard::Repository::Session.new(
        session:,
        key: Schools::AssignExistingMentorWizard::StateStore::REPOSITORY_KEY
      )
    )
  end

  def current_step
    @current_step ||= request.path.split("/").last.underscore.to_sym
  end

  def initialize_wizard
    @wizard = Schools::AssignExistingMentorWizard::Wizard.new(
      current_step:,
      current_step_params: params,
      state_store:
    )
  end
end
