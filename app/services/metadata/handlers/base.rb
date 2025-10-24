module Metadata::Handlers
  class Base
    BATCH_SIZE = 100

    class << self
      def refresh_all_metadata!(async: false, track_changes: false)
        job_method = async ? :perform_later : :perform_now
        object_type = name.demodulize.constantize
        object_type.order(:created_at).in_batches(of: BATCH_SIZE) do |objects|
          RefreshMetadataJob.send(job_method, object_type:, object_ids: objects.pluck(:id), track_changes:)
        end
      end

      def destroy_all_metadata!
        NotImplementedError
      end

    protected

      def truncate_models!(*models)
        models.each { it.connection.execute("TRUNCATE #{it.table_name} RESTART IDENTITY") }
      end
    end

    def track_changes!
      @alert_on_changes = true
    end

  protected

    def lead_provider_ids
      @lead_provider_ids ||= LeadProvider.pluck(:id)
    end

    def changes?(metadata, changes)
      metadata.attributes.slice(*changes.keys) != changes
    end

    def upsert_all(model:, changes_to_upsert:, unique_by:)
      return if changes_to_upsert.empty?

      model.upsert_all(changes_to_upsert.values, unique_by:)
      alert_on_changes(changes: changes_to_upsert)
    end

    def alert_on_changes(changes:)
      return unless @alert_on_changes

      changes.each do |metadata, changed_attributes|
        attrs = {
          class: metadata.class.name,
          id: metadata.id,
          changed_attributes:,
        }

        Rails.logger.warn("[Metadata] #{metadata.class.name} change: #{attrs.inspect}")

        Sentry.with_scope do |scope|
          scope.set_context("metadata_changes", attrs) if scope
          Sentry.capture_message("[Metadata] #{metadata.class.name} change")
        end
      end
    end
  end
end
