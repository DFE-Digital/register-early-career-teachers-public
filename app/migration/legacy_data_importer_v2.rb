class LegacyDataImporterV2
  MIGRATORS = %i[mentor ect].freeze

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
    DataMigration.all.find_each(&:destroy!)

    Metadata::Manager.destroy_all_metadata!

    migrators_in_dependency_order.reverse.each(&:reset!)
  end

private

  def migrators
    Migrators::Base.migrators.reject { |m| m.model.in?(%i[teacher mentorship_period]) }
  end

  def migrators_in_dependency_order
    Migrators::Base.migrators_in_dependency_order.select { |m| migrators.include?(m) }
  end
end
