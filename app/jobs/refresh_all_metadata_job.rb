class RefreshAllMetadataJob < ApplicationJob
  queue_as :metadata

  def perform
    Metadata::Manager.refresh_all_metadata!(async: true, track_changes: true)
  end
end
