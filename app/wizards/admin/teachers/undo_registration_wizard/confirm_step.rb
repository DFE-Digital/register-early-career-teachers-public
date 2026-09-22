module Admin
  module Teachers
    module UndoRegistrationWizard
      class ConfirmStep < Step
        attribute :confirmed, :boolean
        attribute :expected_action, :string
        attribute :expected_training_period_ids, :string
        attribute :expected_mentorship_period_ids, :string
        attribute :expected_at_school_period_gid, :string

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

        validate :reviewed_periods_present

        def self.permitted_params = %i[
          confirmed
          expected_action
          expected_training_period_ids
          expected_mentorship_period_ids
          expected_at_school_period_gid
        ]

        def previous_step = :start

        def next_step = :confirmation

        def save!
          return false unless valid?

          action = wizard.undo_registration!(
            expected_action:,
            **expected_associated_period_ids,
            expected_at_school_period_gid:
          )
          store.undo_action = action
          store.registration_undone = true
          true
        end

      private

        def expected_associated_period_ids
          {
            expected_training_period_ids: expected_training_period_ids.split(",").map(&:to_i),
            expected_mentorship_period_ids: expected_mentorship_period_ids.split(",").map(&:to_i)
          }
        end

        def reviewed_periods_present
          return if expected_training_period_ids &&
            expected_mentorship_period_ids &&
            expected_at_school_period_gid.present?

          errors.add(:base, "Review the periods to undo before confirming")
        end
      end
    end
  end
end
