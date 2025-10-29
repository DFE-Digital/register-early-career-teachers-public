class BuildInductionRecordExportJob < ApplicationJob
  queue_as :migration

  def perform
    Migration::InductionRecordExporter.new.generate_and_cache_csv
  end
end
