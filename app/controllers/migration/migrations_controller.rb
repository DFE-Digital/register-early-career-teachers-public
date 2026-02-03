class Migration::MigrationsController < ::AdminController
  def index
    @data_migrations = DataMigration.order(model: :asc, worker: :asc).all
    @in_progress_migration = @data_migrations.present? && !@data_migrations.all?(&:complete?)
    @completed_migration = @data_migrations.present? && @data_migrations.all?(&:complete?)
  end

  def create
    LegacyDataImporter.new.prepare!
    MigrationJob.perform_later

    redirect_to migration_migrations_path
  end

  def reset
    LegacyDataImporter.new.reset!
    redirect_to migration_migrations_path
  end

  def cache_stats
    @data_migrations = DataMigration.complete.where.not(cache_stats: nil).order(:id)
    @combinations = DataMigrationTeacherCombination.select(
      "SUM(ecf1_ect_combinations_count) AS total_ecf1_ect_combinations,
       SUM(ecf1_mentor_combinations_count) AS total_ecf1_mentor_combinations,
       SUM(ecf2_ect_combinations_count) AS total_ecf2_ect_combinations,
       SUM(ecf2_mentor_combinations_count) AS total_ecf2_mentor_combinations"
    )

    render layout: "full"
  end

  def download_report
    data_migrations = DataMigration.complete.where(model: params[:model])
    failures = FailureManager.combine_failures(data_migrations)

    send_data(failures.to_json, filename: "migration_failures_#{params[:model]}.json", type: :json, disposition: "attachment")
  end
end
