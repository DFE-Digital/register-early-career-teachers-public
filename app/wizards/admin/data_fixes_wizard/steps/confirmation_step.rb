module Admin::DataFixesWizard::Steps
  class ConfirmationStep
    include DfE::Wizard::Step

    delegate :state_store, to: :wizard
    delegate :confirmed_changes, to: :state_store
  end
end
