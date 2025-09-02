module Schools
  module ECTs
    module ChangeEmailAddressWizard
      class ConfirmationStep < BaseStep
        def previous_step = :check_answers

        def new_email = ect_at_school_period.email
      end
    end
  end
end
