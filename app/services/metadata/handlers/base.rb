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

    def upsert(metadata, attributes)
      metadata.assign_attributes(attributes)
      return unless metadata.changed?

      metadata.save!
      alert_on_changes(metadata:, attributes:)
    end

    def lead_provider_ids
      @lead_provider_ids ||= LeadProvider.pluck(:id)
    end

    def alert_on_changes(metadata:, attributes:)
      return unless @alert_on_changes

      attrs = {
        class: metadata.class.name,
        id: metadata.id,
        attributes:
      }

      Rails.logger.warn("[Metadata] #{metadata.class.name} change: #{attrs.inspect}")

      Sentry.with_scope do |scope|
        scope&.set_context("metadata_changes", attrs)
        Sentry.capture_message("[Metadata] #{metadata.class.name} change")
      end
    end
  end
end
