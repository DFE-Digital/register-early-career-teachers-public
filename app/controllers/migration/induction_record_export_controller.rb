class Migration::InductionRecordExportController < Migration::BaseExportController
  def exporter_class = Migration::InductionRecordExporter
end
