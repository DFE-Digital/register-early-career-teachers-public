class Migration::ECF2MigratedCombinationsExportController < Migration::BaseExportController
  def exporter_class = Migration::ECF2MigratedCombinationsExporter
end
