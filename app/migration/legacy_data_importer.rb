class LegacyDataImporter
  # TODO: remove version parameter once V1 migrators are deleted
  def initialize(version: 1)
    @version = version
  end

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

  # TODO: remove filtering once V1 migrators are deleted
  def migrators
    all_migrators = Migrators::Base.migrators

    case @version
    when 1
      all_migrators.reject { |m| m.model.in?(%i[teacher_mentor_data teacher_ect_data]) }
    when 2
      all_migrators.reject { |m| m.model.in?(%i[teacher mentorship_period]) }
    else
      raise ArgumentError, "Unknown migrator version: #{@version}"
    end
  end

  def migrators_in_dependency_order
    graph = migrators.index_by(&:model)

    each_node = ->(&b) { graph.each_key(&b) }
    each_child = ->(model, &b) { graph[model].dependencies.each(&b) }

    TSort.strongly_connected_components(each_node, each_child).flatten.map { |key| graph[key] }
  end
end
