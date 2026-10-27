module Schools
  module InductionTutorable
    extend ActiveSupport::Concern

    included do
      before_action :start_journey, if: -> { current_step == :edit }
      before_action :initialize_wizard
      before_action :reject_incomplete_check_answers, only: :create, if: -> { current_step == :check_answers }
    end

    def new
      render current_step
    end

    def create
      if @wizard.save_current_step
        redirect_to @wizard.next_step_path
      else
        render current_step
      end
    end

  private

    def start_journey
      state_store.prefill_from_school
    end

    def reject_incomplete_check_answers
      return if @wizard.valid_path_to_current_step?

      redirect_to @wizard.resolve_step_path(@wizard.root_step), flash: { error: WizardStoreRescuable::EMPTY_STORE_FLASH_MESSAGE }
    end

    def state_store
      @state_store ||= Schools::InductionTutor::StateStore.new(
        school:,
        repository: DfE::Wizard::Repository::Session.new(session:, key: wizard_key)
      )
    end

    def current_step
      @current_step ||= request.path.split("/").last.underscore.to_sym
    end

    def initialize_wizard
      @wizard = wizard_class.new(
        current_step:,
        current_step_params: params,
        state_store:
      )
    end

    def wizard_class
      "#{wizard_key.camelize}::Wizard".constantize
    end

    def wizard_key
      self.class.name.delete_suffix("Controller").underscore
    end
  end
end
