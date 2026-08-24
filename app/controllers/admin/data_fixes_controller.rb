module Admin
  class DataFixesController < AdminController
    include WizardStoreRescuable

    before_action :set_steps,
                  :set_store,
                  :set_wizard

    before_action -> { redirect_to "/404", as: :not_found },
                  unless: -> { wizard_class.step?(@current_step) }

    before_action -> { @wizard.reset },
                  if: -> { @current_step == :csv },
                  unless: -> { wizard_class.step?(@previous_step) },
                  only: :new

    around_action :wrap_in_transaction,
                  if: -> { @current_step == :preview },
                  only: :create

    def new
      render @current_step
    end

    def create
      if @wizard.save!
        redirect_to @wizard.next_step_path
      else
        render @current_step, status: :unprocessable_content
      end
    end

  private

    def authorised? = current_user&.dfe_user? && current_user.product_team?

    def set_steps
      @current_step = request.path.split("/").last.underscore.to_sym
      @previous_step = request.referer&.split("/")&.last&.underscore&.to_sym
    end

    def set_store
      @store = SessionRepository.new(session:, form_key: :admin_data_fixes_wizard)
    end

    def set_wizard
      @wizard = wizard_class.new(
        current_step: @current_step,
        author: current_user,
        step_params: params,
        store: @store
      )
    end

    def wizard_class = DataFixesWizard::Wizard

    def wrap_in_transaction
      ActiveRecord::Base.transaction do
        yield
        raise ActiveRecord::Rollback
      end
    end
  end
end
