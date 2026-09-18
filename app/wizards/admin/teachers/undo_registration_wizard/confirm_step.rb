module Admin
  module Teachers
    module UndoRegistrationWizard
      class ConfirmStep < Step
        attribute :confirmed, :boolean
        attribute :expected_action, :string

        validates :confirmed,
                  acceptance: {
                    message: ->(step, _) {
                      action = step.wizard.periods_will_be_closed? ? "close" : "delete"

                      "Confirm you want to undo this registration and #{action} this school period"
                    },
                    allow_nil: false
                  }

        validates :expected_action,
                  inclusion: { in: %w[close delete] }

        def self.permitted_params = %i[confirmed expected_action]

        def previous_step = :start

        def next_step = :confirmation

        def save!
          return false unless valid?

          action = wizard.undo_registration!(expected_action:)
          store.undo_action = action
          store.registration_undone = true
          true
        end
      end
    end
  end
end
