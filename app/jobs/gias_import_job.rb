class GIASImportJob < ApplicationJob
  queue_as :default

  def perform
    GIAS::Importer.new(auto_create_school: false).fetch
  end
end
