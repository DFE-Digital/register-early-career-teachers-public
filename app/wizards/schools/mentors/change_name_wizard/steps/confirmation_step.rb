module Schools::Mentors::ChangeNameWizard::Steps
  class ConfirmationStep
    include DfE::Wizard::Step

    def new_name = wizard.state_store.name
  end
end
