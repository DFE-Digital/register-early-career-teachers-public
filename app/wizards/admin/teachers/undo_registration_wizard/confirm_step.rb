module Admin
  module Teachers
    module UndoRegistrationWizard
      class ConfirmStep < Step
        attribute :confirmed, :boolean

        validates :confirmed,
                  acceptance: {
                    message: "Confirm you want to undo this registration and close this school period",
                    allow_nil: false
                  }

        def self.permitted_params = %i[confirmed]

        def previous_step = :start

        def next_step = :confirmation

        def save!
          return false unless valid?

          undo_registration.undo!
          store.registration_undone = true
          true
        end

      private

        def undo_registration
          @undo_registration ||= ::Teachers::UndoRegistration.new(
            author: wizard.author,
            at_school_period: wizard.at_school_period,
            reason: :registered_in_error
          )
        end
      end
    end
  end
end
