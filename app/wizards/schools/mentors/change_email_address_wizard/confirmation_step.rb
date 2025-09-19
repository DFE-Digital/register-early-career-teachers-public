module Schools
  module Mentors
    module ChangeEmailAddressWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_email = mentor_at_school_period.email
      end
    end
  end
end
