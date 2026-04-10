module WizardStoreRescuable
  extend ActiveSupport::Concern

  EMPTY_STORE_FLASH_MESSAGE = <<~TXT.squish
    Your changes were not saved. Please close any other tabs or windows for this
    service, and try again. If the problem persists, please contact support.
  TXT

  included do
    rescue_from ApplicationWizardStep::EmptyStoreError, with: :redirect_to_first_step

  private

    def redirect_to_first_step
      redirect_to @wizard.first_step_path, flash: { error: EMPTY_STORE_FLASH_MESSAGE }
    end
  end
end
