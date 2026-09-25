module Admin
  class DataFixesController < AdminController
    layout "full"

    before_action :set_wizard

    before_action -> { redirect_to "/404", as: :not_found },
                  unless: -> { @wizard.valid_path_to_current_step? }

    before_action -> { @wizard.clear },
                  if: -> { @current_step == :csv && starting_afresh? },
                  only: :new

    around_action :wrap_in_transaction,
                  if: -> { @current_step == :preview },
                  only: :create

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

    def authorised? = super && current_user.product_team?

    def set_wizard
      @current_step = request.path.split("/").last.underscore.to_sym
      @previous_step = request.referer&.split("/")&.last&.underscore&.to_sym
      repository = DfE::Wizard::Repository::Session.new(session:, key: :admin_data_fixes_wizard)
      state_store = DataFixesWizard::StateStore.new(repository:)
      @wizard = DataFixesWizard::Wizard.new(
        current_step: @current_step || :csv,
        current_step_params: params,
        state_store:
      )
    end

    def starting_afresh?
      !@wizard.valid_path_to?(@previous_step) || @previous_step == :confirmation
    end

    def wrap_in_transaction
      ActiveRecord::Base.transaction do
        yield
        raise ActiveRecord::Rollback
      end
    end
  end
end
