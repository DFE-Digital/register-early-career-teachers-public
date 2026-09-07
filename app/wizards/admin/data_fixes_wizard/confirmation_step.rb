module Admin::DataFixesWizard
  class ConfirmationStep < Step
    delegate :confirmed_changes, to: :store
  end
end
