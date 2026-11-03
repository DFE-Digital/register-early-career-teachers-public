module Admin::Teachers::UndoRegistrationWizard::Steps
  class ConfirmStep
    include DfE::Wizard::Step

    attribute :confirmed, :boolean
    attribute :expected_action, :string
    attribute :expected_training_period_ids
    attribute :expected_mentorship_period_ids
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

    def self.permitted_params = [
      :confirmed,
      :expected_action,
      :expected_at_school_period_gid,
      {
        expected_training_period_ids: [],
        expected_mentorship_period_ids: []
      }
    ]

  private

    def reviewed_periods_present
      return if expected_training_period_ids &&
        expected_mentorship_period_ids &&
        expected_at_school_period_gid.present?

      errors.add(:base, "Review the periods to undo before confirming")
    end
  end
end
