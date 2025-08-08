class RefreshMetadataJob < ApplicationJob
  queue_as :metadata

  def perform(object_type:, object_ids:)
    objects = object_type.where(id: object_ids)
    Metadata::Manager.new.refresh_metadata!(objects)
  end
end
