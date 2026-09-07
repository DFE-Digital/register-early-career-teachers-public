module Admin::DataFixesWizard
  class VerifyStep < Step
    def previous_step = :preview
    def next_step = :confirmation

    def save!
      confirmed_changes = changes.process
      store.confirmed_changes = confirmed_changes.presence || nil
    end

    delegate :errors, to: :changes
    delegate :processed_changes, to: :store

  private

    def changes
      @changes ||= Admin::DataFixes::Changes.new(parsed_rows: store.parsed_rows)
    end
  end
end
