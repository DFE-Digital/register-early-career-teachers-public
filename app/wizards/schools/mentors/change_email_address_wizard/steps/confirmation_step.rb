module Schools::Mentors::ChangeEmailAddressWizard::Steps
  class ConfirmationStep
    include DfE::Wizard::Step

    delegate :mentor_at_school_period, to: :wizard
    def new_email = mentor_at_school_period.email
  end
end
