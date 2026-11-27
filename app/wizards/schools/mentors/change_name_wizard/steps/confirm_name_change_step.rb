module Schools::Mentors::ChangeNameWizard::Steps
  class ConfirmNameChangeStep
    include DfE::Wizard::Step
    include Schools::ChangeName::Confirmable

    def new_name = wizard.state_store.name
  end
end
