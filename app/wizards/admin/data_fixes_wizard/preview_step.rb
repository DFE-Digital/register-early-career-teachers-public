module Admin::DataFixesWizard
  class PreviewStep < Step
    def previous_step = :csv
    def next_step = :verify

    def save!
      processed_changes = changes.process
      store.processed_changes = processed_changes.presence || nil
    end

    delegate :errors, to: :changes
    delegate :parsed_rows, to: :store

  private

    def changes
      @changes ||= Admin::DataFixes::Changes.new(parsed_rows: store.parsed_rows)
    end
  end
end
