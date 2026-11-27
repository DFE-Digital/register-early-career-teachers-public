module Schools::Mentors::ChangeEmailAddressWizard::Steps
  class CheckAnswersStep
    include DfE::Wizard::Step

    delegate :mentor_at_school_period, :state_store, to: :wizard

    def current_email = mentor_at_school_period.email
    def new_email = state_store.email
  end
end
