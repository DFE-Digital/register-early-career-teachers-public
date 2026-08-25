class GIASImportJob < RecurringJob
  queue_as :default

  def perform
    urns = GIAS::Importer.new.fetch
    GIAS::Reconcile.new(urns).call
  end
end
