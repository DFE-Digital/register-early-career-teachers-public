class Migration::FailedMentorshipsExportController < Migration::BaseExportController
  def exporter_class = Migration::FailedMentorshipsExporter
end
