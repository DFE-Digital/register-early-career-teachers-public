class RefreshMetadataJob < ApplicationJob
  queue_as :metadata

  limits_concurrency to: 2, key: :refresh_metadata

  def perform(object_type:, object_ids:, track_changes: false)
    objects = object_type.where(id: object_ids)
    Metadata::Manager.new.refresh_metadata!(objects, track_changes:)
  end
end
