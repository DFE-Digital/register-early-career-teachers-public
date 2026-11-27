module Schools::Mentors::ChangeNameWizard::Steps
  class CheckAnswersStep
    include DfE::Wizard::Step

    def current_name = wizard.teacher_full_name
    def new_name = wizard.state_store.name
  end
end
