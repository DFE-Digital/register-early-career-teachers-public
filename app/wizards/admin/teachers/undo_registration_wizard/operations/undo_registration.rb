module Admin::Teachers::UndoRegistrationWizard::Operations
  class UndoRegistration
    def initialize(repository:, step:)
      @repository = repository
      @step = step
    end

    def execute
      action = state_store.undo_registration!(
        expected_action: step.expected_action,
        expected_training_period_ids: step.expected_training_period_ids.compact_blank.map(&:to_i),
        expected_mentorship_period_ids: step.expected_mentorship_period_ids.compact_blank.map(&:to_i),
        expected_at_school_period_gid: step.expected_at_school_period_gid
      )
      repository.write(undo_action: action, registration_undone: true)

      { success: true }
    end

  private

    attr_reader :repository, :step

    delegate :wizard, to: :step, private: true
    delegate :state_store, to: :wizard, private: true
  end
end
