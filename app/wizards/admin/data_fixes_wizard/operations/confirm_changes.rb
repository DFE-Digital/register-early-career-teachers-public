module Admin::DataFixesWizard::Operations
  class ConfirmChanges
    def initialize(repository:, step:)
      @repository = repository
      @step = step
      @state_store = step.state_store
    end

    def execute
      if process_changes
        { success: true }
      else
        { success: false, errors: step.errors }
      end
    end

  private

    def process_changes
      ActiveRecord::Base.transaction do
        if changes.valid?
          step.confirmed_changes = changes.results.map(&:saved_change)
          changes.results.each { record_event!(it) }
        else
          step.confirmed_changes = nil
          step.errors.add(:base, "There was an error processing changes. All changes have been reverted.")
          step.errors.merge!(changes.errors)
          raise ActiveRecord::Rollback
        end
      end
    end

    attr_reader :repository, :step, :state_store

    def changes
      @changes ||= Admin::DataFixes::Changes.new(parsed_rows: state_store.parsed_rows)
    end

    def record_event!(result)
      saved_change = result.saved_change
      Events::Record.record_admin_data_fix_event!(
        author: step.author,
        body: step.note,
        zendesk_ticket_id: step.zendesk_ticket_id,
        modifications: saved_change&.fetch(:changes),
        metadata: saved_change,
        record: result.target_object
      )
    end
  end
end
