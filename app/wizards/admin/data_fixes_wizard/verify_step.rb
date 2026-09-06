module Admin::DataFixesWizard
  class VerifyStep < Step
    include Auditable

    def self.permitted_params = auditable_params[model_name.param_key]

    def previous_step = :preview
    def next_step = :confirmation

    def save!
      return false unless valid?

      ActiveRecord::Base.transaction do
        confirmed_changes = changes.process
        store.confirmed_changes = confirmed_changes.presence || nil

        if confirmed_changes
          confirmed_changes.each { record_event!(it) }
        else
          changes.errors.add(:base, "There was an error processing changes. All changes have been reverted.")
          errors.merge!(changes.errors)
          raise ActiveRecord::Rollback
        end
      end
    end

    delegate :author, to: :wizard
    delegate :processed_changes, to: :store

  private

    def record_event!(change)
      Events::Record.record_admin_data_fix_event!(
        author:,
        body: note,
        zendesk_ticket_id:,
        modifications: change.fetch(:changes),
        metadata: change
      )
    end

    def changes
      @changes ||= Admin::DataFixes::Changes.new(parsed_rows: store.parsed_rows)
    end
  end
end
