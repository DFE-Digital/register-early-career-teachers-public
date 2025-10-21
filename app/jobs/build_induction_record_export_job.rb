class BuildInductionRecordExportJob < ApplicationJob
  def perform
    Migration::InductionRecordExporter.new.generate_and_cache_csv
  end
end
