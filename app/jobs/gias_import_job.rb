class GIASImportJob < ApplicationJob
  queue_as :default

  # TODO: Enable automatic reconciliation
  def perform
    GIAS::Importer.new.fetch
  end
end
