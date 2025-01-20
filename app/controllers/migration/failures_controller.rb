class Migration::FailuresController < ::AdminController
  layout "full"

  def index
    @failures = grouped_failures
  end

private

  def grouped_failures
    migrator_models.map do |model|
      {
        model:,
        failures: MigrationFailure.joins(:data_migration).where(data_migration: { model: }).group(:failure_message).count
      }
    end
  end

  def migrator_names
    @migrator_names ||= migrator_models.map(&:humanize)
  end

  def migrator_models
    @migrator_models ||= migrators.map { |m| m.model }.sort
  end

  def migrators
    Migrators::Base.migrators
  end
end
