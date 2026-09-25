module Admin::DataFixesWizard::Operations
  class ProcessChanges
    def initialize(repository:, step:)
      @repository = repository
      @step = step
      @state_store = step.state_store
    end

    def execute
      if changes.valid?
        step.processed_changes = changes.results.map(&:saved_change)
        { success: true }
      else
        step.processed_changes = nil
        step.errors.merge!(changes.errors)
        { success: false, errors: step.errors }
      end
    end

  private

    attr_reader :repository, :step, :state_store

    def changes
      @changes ||= Admin::DataFixes::Changes.new(parsed_rows: state_store.parsed_rows)
    end
  end
end
