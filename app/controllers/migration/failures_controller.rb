class Migration::FailuresController < ::AdminController
  layout "full"

  def index
    @teacher_failures = teacher_grouped_failures
    @failures = generic_grouped_failures
  end

private

  def teacher_grouped_failures
    failures = TeacherMigrationFailure.all
    failure_group.new(:teacher, failures.count, failures.group(:message).count.sort.to_h)
  end

  def generic_grouped_failures
    migrator_models.map do |model|
      failures = migration_failures_for_model(model:)
      failure_group.new(model, failures.count, failures.group(:failure_message).count.sort.to_h)
    end
  end

  def failure_group
    @failure_group ||= Data.define(:model, :failure_count, :failures)
  end

  def migration_failures_for_model(model:)
    MigrationFailure.joins(:data_migration).where(data_migration: { model: })
  end

  def migrator_models
    @migrator_models ||= migrators.map(&:model)
  end

  def migrators
    Migrators::Base.migrators_in_dependency_order
  end
end
