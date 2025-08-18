module Metadata::Handlers
  class Base
    BATCH_SIZE = 100

    class << self
      def refresh_all_metadata!(async: false)
        job_method = async ? :perform_later : :perform_now
        object_type = name.demodulize.constantize
        object_type.order(:created_at).in_batches(of: BATCH_SIZE) do |objects|
          RefreshMetadataJob.send(job_method, object_type:, object_ids: objects.pluck(:id))
        end
      end
    end

  protected

    def upsert(metadata, attributes)
      metadata.assign_attributes(attributes)
      metadata.save! if metadata.changed?
    end

    def lead_provider_ids
      @lead_provider_ids ||= LeadProvider.pluck(:id)
    end
  end
end
