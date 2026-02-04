class Migration::FailedCombinationsExportController < Migration::BaseExportController
  def exporter_class = Migration::FailedCombinationsExporter
end
