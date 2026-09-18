module Admin
  module Teachers
    module UndoRegistrationWizard
      class ConfirmStep < Step
        attribute :confirmed, :boolean

        validates :confirmed,
                  acceptance: {
                    message: ->(step, _) {
                      action = step.wizard.periods_will_be_closed? ? "close" : "delete"

                      "Confirm you want to undo this registration and #{action} this school period"
                    },
                    allow_nil: false
                  }

        def self.permitted_params = %i[confirmed]

        def previous_step = :start

        def next_step = :confirmation

        def save!
          return false unless valid?

          wizard.undo_registration!
          store.registration_undone = true
          true
        end
      end
    end
  end
end
