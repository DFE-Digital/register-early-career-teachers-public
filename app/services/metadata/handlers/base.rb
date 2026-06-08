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

    def update_metadata!(metadata, latest_attributes)
      # As we touch other models when metadata is updated via ActiveRecord callbacks,
      # we need to ensure this remains a method that will trigger those callbacks
      # (rather than using something like upsert_all which would otherwise be quicker).
      metadata.update!(latest_attributes)
      alert_on_changes(metadata)
    end

    # Allows individual handlers to exclude attributes that we can't
    # reliably update at the moment they change. Prevents them from
    # being included in the alerts.
    def alertable_changes(saved_changes) = saved_changes

    def alert_on_changes(metadata)
      return unless @alert_on_changes

      alertable_changes = alertable_changes(metadata.saved_changes)

      return unless alertable_changes.any?

      attrs = {
        class: metadata.class.name,
        id: metadata.id,
        alertable_changes:
      }

      Rails.logger.warn("[Metadata] #{metadata.class.name} change: #{attrs.inspect}")

      Sentry.with_scope do |scope|
        scope.set_context("metadata_changes", attrs) if scope
        Sentry.capture_message("[Metadata] #{metadata.class.name} change")
      end
    end
  end
end
