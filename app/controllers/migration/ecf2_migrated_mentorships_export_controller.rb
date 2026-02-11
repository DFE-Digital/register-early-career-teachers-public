class Migration::ECF2MigratedMentorshipsExportController < Migration::BaseExportController
  def exporter_class = Migration::ECF2MigratedMentorshipsExporter
end
