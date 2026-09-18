module Admin
  module Teachers
    module UndoRegistrationWizard
      class ConfirmStep < Step
        def previous_step = :start

        def next_step = :confirmation
      end
    end
  end
end
