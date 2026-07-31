class GIASImportJob < ApplicationJob
  queue_as :default

  def perform
    GIAS::Importer.new.fetch
  end
end
