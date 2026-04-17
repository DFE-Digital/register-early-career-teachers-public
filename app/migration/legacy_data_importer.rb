class LegacyDataImporter
  def prepare!
    migrators.each(&:prepare!)
  end

  def migrate!
    migrators_in_dependency_order.each do |migrator|
      migrator.queue if migrator.runnable?
    end

    Metadata::Manager.refresh_all_metadata!(async: true) if DataMigration.incomplete.none?
  end

  def reset!
    # FIXME: could cause an issue if there are any jobs in process, plus do
    # we want to do this?
    DataMigration.all.find_each(&:destroy!)

    Metadata::Manager.destroy_all_metadata!

    migrators_in_dependency_order.reverse.each(&:reset!)
  end

private

  def migrators
    Migrators::Base.migrators
  end

  def migrators_in_dependency_order
    Migrators::Base.migrators_in_dependency_order
  end
end
