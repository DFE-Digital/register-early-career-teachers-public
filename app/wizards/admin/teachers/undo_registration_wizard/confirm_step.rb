module Admin
  module Teachers
    module UndoRegistrationWizard
      class ConfirmStep < Step
        attribute :confirmed, :boolean
        attribute :expected_action, :string
        attribute :expected_training_period_ids, :string
        attribute :expected_mentorship_period_ids, :string

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

        validate :reviewed_period_ids_present

        def self.permitted_params = %i[
          confirmed
          expected_action
          expected_training_period_ids
          expected_mentorship_period_ids
        ]

        def previous_step = :start

        def next_step = :confirmation

        def save!
          return false unless valid?

          action = wizard.undo_registration!(expected_action:, **expected_period_ids)
          store.undo_action = action
          store.registration_undone = true
          true
        end

      private

        def expected_period_ids
          {
            expected_training_period_ids: expected_training_period_ids.split(",").map(&:to_i),
            expected_mentorship_period_ids: expected_mentorship_period_ids.split(",").map(&:to_i)
          }
        end

        def reviewed_period_ids_present
          return if expected_training_period_ids && expected_mentorship_period_ids

          errors.add(:base, "Review the periods to undo before confirming")
        end
      end
    end
  end
end
