module WizardStoreRescuable
  extend ActiveSupport::Concern

  included do
    rescue_from ApplicationWizardStep::StoreEmptyError, with: :redirect_to_first_step

  private

    def redirect_to_first_step
      redirect_to @wizard.first_step_path, alert: ApplicationWizardStep::STORE_EMPTY_FLASH_MESSAGE
    end
  end
end
